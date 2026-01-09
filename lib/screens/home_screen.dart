import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ecommerce_app/cubits/product/product_cubit.dart';
import 'package:ecommerce_app/cubits/product/product_state.dart';
import 'package:ecommerce_app/cubits/cart/cart_cubit.dart';
import 'package:ecommerce_app/cubits/cart/cart_state.dart';
import 'package:ecommerce_app/cubits/view_mode/view_mode_cubit.dart';
import 'package:ecommerce_app/widgets/product_card.dart';
import 'cart_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('E-Commerce Shop'),
        actions: [
          BlocBuilder<ViewModeCubit, ViewMode>(
            builder: (context, viewMode) {
              return IconButton(
                icon: Icon(
                  viewMode == ViewMode.grid ? Icons.list : Icons.grid_view,
                ),
                onPressed: () {
                  context.read<ViewModeCubit>().toggleViewMode();
                },
              );
            },
          ),
          BlocBuilder<CartCubit, CartState>(
            builder: (context, state) {
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CartScreen(),
                        ),
                      );
                    },
                  ),
                  if (state.itemCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '${state.itemCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          context.read<ProductCubit>().searchProducts('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: (value) {
                context.read<ProductCubit>().searchProducts(value);
                setState(() {});
              },
            ),
          ),
          BlocBuilder<ProductCubit, ProductState>(
            builder: (context, state) {
              if (state is ProductLoaded) {
                return SizedBox(
                  height: 50, 
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    children: [
                      _buildCategoryChip(context, 'All', 'All', state.selectedCategory),
                      ...state.categories.map((category) {
                        return _buildCategoryChip(
                          context,
                          category,
                          category,
                          state.selectedCategory,
                        );
                      }),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          BlocBuilder<ProductCubit, ProductState>(
            builder: (context, state) {
              if (state is ProductLoaded) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Sort by:', 
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildSortChip(context, 'Default', 'none', state.sortBy),
                              _buildSortChip(context, 'Price: Low-High', 'price_low', state.sortBy),
                              _buildSortChip(context, 'Price: High-Low', 'price_high', state.sortBy),
                              _buildSortChip(context, 'Rating', 'rating', state.sortBy),
                              _buildSortChip(context, 'Name', 'name', state.sortBy),
                            ],
                          ),
                        ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          const Divider(),

          Expanded(
            child: BlocBuilder<ProductCubit, ProductState>(
              builder: (context, state) {
                if (state is ProductLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is ProductError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          state.message,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            context.read<ProductCubit>().loadProducts();
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                } else if (state is ProductLoaded) {
                  if (state.filteredProducts.isEmpty) {
                    return const Center(
                      child: Text('No products found'),
                    );
                  }

                  return BlocBuilder<ViewModeCubit, ViewMode>(
                    builder: (context, viewMode) {
                      return RefreshIndicator(
                        onRefresh: () async {
                          context.read<ProductCubit>().loadProducts();
                        },
                        child: viewMode == ViewMode.grid
                            ? GridView.builder(
                                padding: const EdgeInsets.all(8),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 0.65,
                                  crossAxisSpacing: 8,
                                  mainAxisSpacing: 8,
                                ),
                                itemCount: state.filteredProducts.length,
                                itemBuilder: (context, index) {
                                  return ProductCard(
                                    product: state.filteredProducts[index],
                                    isGridView: true,
                                  );
                                },
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.all(8),
                                itemCount: state.filteredProducts.length,
                                itemBuilder: (context, index) {
                                  return ProductCard(
                                    product: state.filteredProducts[index],
                                    isGridView: false,
                                  );
                                },
                              ),
                      );
                    },
                  );
                }
                return const Center(child: Text('No products available'));
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(
    BuildContext context,
    String label,
    String? category,
    String? selectedCategory,
  ) {
    final bool isSelected;
   
      isSelected = selectedCategory == category;


    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) {
          context.read<ProductCubit>().filterByCategory(category);
        }
      ),
    );
  }

  Widget _buildSortChip(
    BuildContext context,
    String label,
    String sortBy,
    String currentSort,
  ) {
    final isSelected = sortBy == currentSort;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) {
            context.read<ProductCubit>().sortProducts(sortBy);
          }
        },
      ),
    );
  }
}