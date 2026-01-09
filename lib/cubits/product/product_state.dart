import 'package:equatable/equatable.dart';
import 'package:ecommerce_app/models/product.dart';

abstract class ProductState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ProductInitial extends ProductState {}

class ProductLoading extends ProductState {}

class ProductLoaded extends ProductState {
  final List<Product> products;
  final List<Product> filteredProducts;
  final String searchQuery;
  final String? selectedCategory;
  final String sortBy;

  ProductLoaded({
    required this.products,
    List<Product>? filteredProducts,
    this.searchQuery = '',
    this.selectedCategory,
    this.sortBy = 'none',
  }) : filteredProducts = filteredProducts ?? products;

  ProductLoaded copyWith({
    List<Product>? products,
    List<Product>? filteredProducts,
    String? searchQuery,
    String? selectedCategory,
    String? sortBy,
  }) {
    return ProductLoaded(
      products: products ?? this.products,
      filteredProducts: filteredProducts ?? this.filteredProducts,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      sortBy: sortBy ?? this.sortBy,
    );
  }

  List<String> get categories {
    return products.map((p) => p.category).toSet().toList()..sort();
  }

  @override
  List<Object?> get props => [
        products,
        filteredProducts,
        searchQuery,
        selectedCategory,
        sortBy,
      ];
}

class ProductError extends ProductState {
  final String message;

  ProductError(this.message);

  @override
  List<Object?> get props => [message];
}