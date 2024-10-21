import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class InAppPurchasePage extends StatefulWidget {
  @override
  _InAppPurchasePageState createState() => _InAppPurchasePageState();
}

class _InAppPurchasePageState extends State<InAppPurchasePage> {
  String _selectedProductId = 'sub_trial'; // Preselect trial
  bool _isSelectionChanged = false; // Tracks if user changed selection
  final InAppPurchase _iap = InAppPurchase.instance;

  final List<Map<String, String>> _subscriptionPlans = [
    {
      'title': '14-Day Free Trial',
      'description': 'Get started with a free trial.',
      'price': '\$0.00',
      'id': 'sub_trial'
    },
    {
      'title': 'Monthly Subscription',
      'description': 'Enjoy monthly access to premium features.',
      'price': '\$4.99',
      'id': 'sub_month'
    },
    {
      'title': 'Yearly Subscription',
      'description': 'Save more with an annual plan.',
      'price': '\$49.99',
      'id': 'sub_year'
    }
  ];

  @override
  void initState() {
    super.initState();
    // Initialize In-App Purchase listener
    _iap.purchaseStream.listen((purchaseDetailsList) {
      _listenToPurchaseUpdated(purchaseDetailsList);
    });
  }

  void _onSubscribe() {
    if (_selectedProductId != null) {
      // Show a confirmation dialog
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Confirm Subscription'),
            content: Text('Do you want to subscribe to $_selectedProductId?'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog
                },
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  _purchaseProduct(_selectedProductId);
                  Navigator.of(context).pop(); // Close the dialog
                },
                child: Text('Confirm'),
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> _purchaseProduct(String productId) async {
    // Create a Set from the single productId
    final ProductDetailsResponse response = await _iap.queryProductDetails({productId}.toSet());
    if (response.notFoundIDs.isNotEmpty) {
      // Show a SnackBar if the product ID was not found
      _showSnackBar('Product not found: $productId');
      return;
    }

    final PurchaseParam purchaseParam = PurchaseParam(productDetails: response.productDetails.first);
    await _iap.buyConsumable(purchaseParam: purchaseParam);
  }

  void _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {
    for (var purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.purchased) {
        _handleSuccessfulPurchase(purchaseDetails);
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        // Handle the error case
        _showSnackBar("Purchase error: ${purchaseDetails.error}");
      }
    }
  }

  void _handleSuccessfulPurchase(PurchaseDetails purchaseDetails) {
    // Validate purchase and update your app state
    print("Purchase successful: ${purchaseDetails.productID}");
    _showSnackBar("Purchase successful: ${purchaseDetails.productID}");
    InAppPurchase.instance.completePurchase(purchaseDetails);
  }

  void _showSnackBar(String message) {
    final snackBar = SnackBar(content: Text(message));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Widget _buildSubscriptionOption({
    required String title,
    required String description,
    required String price,
    required String productId,
  }) {
    return RadioListTile<String>(
      title: Text(title),
      subtitle: Text(description),
      value: productId,
      groupValue: _selectedProductId,
      onChanged: (value) {
        setState(() {
          _selectedProductId = value!;
          _isSelectionChanged = true; // Mark selection as changed
        });
      },
      secondary: Text(price),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Subscription'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: _subscriptionPlans.map((plan) {
                return _buildSubscriptionOption(
                  title: plan['title']!,
                  description: plan['description']!,
                  price: plan['price']!,
                  productId: plan['id']!,
                );
              }).toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 20.0, bottom: 50.0), // Adjust padding as needed
            child: Align(
              alignment: Alignment.centerLeft,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), // Optionally make it rounder
                ),
                onPressed: _isSelectionChanged ? _onSubscribe : null, // Disable button until user changes selection
                child: Text('Subscribe Now'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
