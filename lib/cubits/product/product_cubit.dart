import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ecommerce_app/services/api_service.dart';
import 'package:ecommerce_app/models/product.dart';
import 'product_state.dart';

class ProductCubit extends Cubit<ProductState> {
  final ApiService apiService;
  final SharedPreferences prefs;

  ProductCubit({
    required this.apiService,
    required this.prefs,
  }) : super(ProductInitial()) {
    loadProducts();
  }

  Future<void> loadProducts() async {
    emit(ProductLoading());
    
    try {
      final products = await apiService.fetchProducts();
      final productsJson = products.map((p) => p.toJson()).toList();
      await prefs.setString('cached_products', json.encode(productsJson));
      emit(ProductLoaded(products: products));
    } catch (e) {
      final cachedData = prefs.getString('cached_products');
      
      if (cachedData != null) {
        try {
          final List<dynamic> decoded = json.decode(cachedData);
          final products = decoded.map((json) => Product.fromJson(json)).toList();
          emit(ProductLoaded(products: products));
        } catch (_) {
          emit(ProductError('Failed to load products: $e'));
        }
      } else {
        emit(ProductError('Failed to load products: $e'));
      }
    }
  }

  void searchProducts(String query) {
    if (state is ProductLoaded) {
      final currentState = state as ProductLoaded;
      
      var filtered = currentState.products.where((product) {
        final titleMatch = product.title.toLowerCase().contains(query.toLowerCase());
        final descMatch = product.description.toLowerCase().contains(query.toLowerCase());
        return titleMatch || descMatch;
      }).toList();

      if (currentState.selectedCategory != null) {
        filtered = filtered.where((p) => p.category == currentState.selectedCategory).toList();
      }

      filtered = _sortProducts(filtered, currentState.sortBy);

      emit(currentState.copyWith(
        filteredProducts: filtered,
        searchQuery: query,
      ));
    }
  }

  void filterByCategory(String? category) {
    if (state is ProductLoaded) {
      final currentState = state as ProductLoaded;
      
      var filtered = currentState.products;

     if (category != 'All' && category != null) {
        filtered = filtered.where((p) => p.category == category).toList();
      }

      if (currentState.searchQuery.isNotEmpty) {
        filtered = filtered.where((product) {
          final titleMatch = product.title.toLowerCase().contains(currentState.searchQuery.toLowerCase());
          final descMatch = product.description.toLowerCase().contains(currentState.searchQuery.toLowerCase());
          return titleMatch || descMatch;
        }).toList();
      }

      filtered = _sortProducts(filtered, currentState.sortBy);

      emit(currentState.copyWith(
        filteredProducts: filtered,
        selectedCategory: category,
      ));
    }
  }

  void sortProducts(String sortBy) {
    if (state is ProductLoaded) {
      final currentState = state as ProductLoaded;
      final sorted = _sortProducts(List.from(currentState.filteredProducts), sortBy);
      
      emit(currentState.copyWith(
        filteredProducts: sorted,
        sortBy: sortBy,
      ));
    }
  }

  List<Product> _sortProducts(List<Product> products, String sortBy) {
    final sorted = List<Product>.from(products);
    
    switch (sortBy) {
      case 'price_low':
        sorted.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'price_high':
        sorted.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'rating':
        sorted.sort((a, b) => b.rating.rate.compareTo(a.rating.rate));
        break;
      case 'name':
        sorted.sort((a, b) => a.title.compareTo(b.title));
        break;
      default:
        break;
    }
    
    return sorted;
  }

  void clearFilters() {
    if (state is ProductLoaded) {
      final currentState = state as ProductLoaded;
      emit(ProductLoaded(
        products: currentState.products,
        filteredProducts: currentState.products,
      ));
    }
  }
}