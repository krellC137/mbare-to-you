import 'package:customer_app/features/cart/models/cart_item.dart';
import 'package:mbare_core/mbare_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'cart_provider.g.dart';

/// Cart state containing all cart items
class CartState {
  const CartState({this.items = const {}});

  final Map<String, CartItem> items;

  /// Total number of items in cart
  int get itemCount => items.values.fold(0, (sum, item) => sum + item.quantity);

  /// Total price of all items in cart
  double get totalPrice =>
      items.values.fold(0.0, (sum, item) => sum + item.totalPrice);

  /// Get all cart items as a list
  List<CartItem> get itemsList => items.values.toList();

  /// Check if cart is empty
  bool get isEmpty => items.isEmpty;

  /// Check if cart has items
  bool get isNotEmpty => items.isNotEmpty;

  /// Create a copy with updated items
  CartState copyWith({Map<String, CartItem>? items}) {
    return CartState(items: items ?? this.items);
  }
}

/// Cart notifier for managing cart state
@riverpod
class Cart extends _$Cart {
  @override
  CartState build() {
    return const CartState();
  }

  /// Add item to cart
  void addItem(ProductModel product, {int quantity = 1}) {
    final items = Map<String, CartItem>.from(state.items);

    if (items.containsKey(product.id)) {
      // Update quantity if item already exists
      final existingItem = items[product.id]!;
      items[product.id] = existingItem.copyWith(
        quantity: existingItem.quantity + quantity,
      );
    } else {
      // Add new item
      items[product.id] = CartItem(product: product, quantity: quantity);
    }

    state = state.copyWith(items: items);
  }

  /// Remove item from cart
  void removeItem(String productId) {
    final items = Map<String, CartItem>.from(state.items);
    items.remove(productId);
    state = state.copyWith(items: items);
  }

  /// Update item quantity
  void updateQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      removeItem(productId);
      return;
    }

    final items = Map<String, CartItem>.from(state.items);
    final item = items[productId];

    if (item != null) {
      items[productId] = item.copyWith(quantity: quantity);
      state = state.copyWith(items: items);
    }
  }

  /// Increment item quantity
  void incrementQuantity(String productId) {
    final item = state.items[productId];
    if (item != null) {
      updateQuantity(productId, item.quantity + 1);
    }
  }

  /// Decrement item quantity
  void decrementQuantity(String productId) {
    final item = state.items[productId];
    if (item != null) {
      updateQuantity(productId, item.quantity - 1);
    }
  }

  /// Clear all items from cart
  void clear() {
    state = const CartState();
  }

  /// Get quantity of a specific product in cart
  int getQuantity(String productId) {
    return state.items[productId]?.quantity ?? 0;
  }

  /// Check if product is in cart
  bool hasProduct(String productId) {
    return state.items.containsKey(productId);
  }
}
