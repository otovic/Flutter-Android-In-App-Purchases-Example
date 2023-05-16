import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:in_app_purchase_storekit/store_kit_wrappers.dart';

import 'dart:async';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  //We will be subscribing to the stream type List<PurchaseDetails>
  late StreamSubscription<List<PurchaseDetails>> subscription;

  bool isPlatformAvailable = false;
  String purchaseStatus = 'Idle';

  @override
  void initState() {
    //Initialize the stream from InAppPurchase instance
    final Stream<List<PurchaseDetails>> purchaseUpdated =
        InAppPurchase.instance.purchaseStream;

    //We subscribe to the stream and everytime we make a purchase a value of
    //List<PurchaseDetails> will be passed to that stream
    subscription = purchaseUpdated.listen(
      (purchaseDetailsList) {
        listenToPurchaseUpdated(purchaseDetailsList);
      },
      onDone: () {
        subscription.cancel();
      },
      onError: (error) {},
    );

    super.initState();
  }

  @override
  void dispose() {
    subscription.cancel();
    super.dispose();
  }

  //This is a function to buy a product. It receives a Set of product IDs that
  //you specified in your Google Play Console for your app. BuildContext is used
  //to display SnackBar.
  Future<void> buyProduct(Set<String> IDs, BuildContext context) async {
    try {
      //Check if platform is available
      final bool available = await InAppPurchase.instance.isAvailable();

      //If platform is not available we display error
      if (!available) {
        isPlatformAvailable = false;
        showAlert(context, Colors.red, "Cant initialize platform!");
        return;
      }

      //If platform is available we set bool variable isPlatformAvailabel to true
      //Value will also update on screen
      setState(() {
        isPlatformAvailable = true;
      });

      //Assign provided IDs to a new Set of IDs
      Set<String> listOfProductIDs = IDs;

      //Get the details of products that have their IDs listed in listOfProductIDs
      final ProductDetailsResponse response =
          await InAppPurchase.instance.queryProductDetails(listOfProductIDs);

      //We check if there was no error getting details of products
      if (response.error != null) {
        showAlert(context, Colors.red, "Error: ${response.error.toString()}");
        isPlatformAvailable = false;
        return;
      }

      //This will execute if some IDs havent been found
      if (response.notFoundIDs.isNotEmpty) {
        showAlert(context, Colors.red, "Didn't find product with given IDs!");
        isPlatformAvailable = false;
        return;
      }

      //Get found products from response. You can fetch many products or just one,
      //it depends on how many ids you add in Set above
      List<ProductDetails> products = response.productDetails;

      //You can retrieve many products, here i will be working with the first product
      //in the list because im passing only 1 id to the Set and getting only 1 product back.
      final ProductDetails productDetails = products[0];

      //create PurchaseParam from the product you selected from the list above.
      final PurchaseParam purchaseParam =
          PurchaseParam(productDetails: productDetails);

      //Finally you buy your product.
      //NOTE: if your product is consumable make sure to execute .buyConsumableMethod,
      //if your product is non-consumable make sure to execute .buyNonConsumable method
      //otherwise you will get an error.

      //IMPORTANT: if your product is consumable you need to consume it when the user buys it
      //otherwise they will be stuck and wont be able to buy this product anymore
      //the method .buyConsumable has a parameter autoConsume which is a bool
      //indicating if the product should be auto consumed. The product below is auto consumed.
      //In the official docs of the in app purchases for Flutter it is advised to always
      //verify the purchase before delivering the product.
      //Check the listenToPurchaseUpdated method to see how to consume it after verification
      await InAppPurchase.instance
          .buyConsumable(purchaseParam: purchaseParam, autoConsume: true);
    } on Exception catch (e) {
      showAlert(context, Colors.red, e.toString());
    }
  }

  //We need a separate method for Subscriptions.
  //NOTE: Subscriptions are of type NonConsumable so you need to call .buyNonConsumable
  //otherwise you will get an error. Everything is the same like in the above method
  //excpet the buyNonConsumable call at the end.
  Future<void> buySubscription(Set<String> IDs, BuildContext context) async {
    try {
      final bool available = await InAppPurchase.instance.isAvailable();

      if (!available) {
        isPlatformAvailable = false;
        showAlert(context, Colors.red, "Cant initialize platform!");
        return;
      }

      setState(() {
        isPlatformAvailable = true;
      });

      Set<String> listOfProductIDs = IDs;

      final ProductDetailsResponse response =
          await InAppPurchase.instance.queryProductDetails(listOfProductIDs);

      if (response.error != null) {
        showAlert(context, Colors.red, "Error: ${response.error.toString()}");
        isPlatformAvailable = false;
        return;
      }

      if (response.notFoundIDs.isNotEmpty) {
        showAlert(
            context, Colors.red, "Didn't find subscription with given IDs!");
        isPlatformAvailable = false;
        return;
      }

      List<ProductDetails> products = response.productDetails;

      final ProductDetails productDetails = products[0];

      final PurchaseParam purchaseParam =
          PurchaseParam(productDetails: productDetails);

      //NOTE: Again very important subscriptions are always nonConsumable so make sure you call the correct method
      //.buyNonConsumable doesn't have the autoConsume param
      await InAppPurchase.instance
          .buyNonConsumable(purchaseParam: purchaseParam);
    } on Exception catch (e) {
      showAlert(context, Colors.red, e.toString());
    }
  }

  //This method executes everytime a new purchase has been made
  Future<void> listenToPurchaseUpdated(
      List<PurchaseDetails> purchaseDetailsList) async {
    //We loop through every purchase in the list
    try {
      purchaseDetailsList.forEach(
        (PurchaseDetails purchaseDetails) async {
          //If current status of purchase is pending we update the status
          if (purchaseDetails.status == PurchaseStatus.pending) {
            //{Replace with your code}
            setState(() {
              purchaseStatus = "Pending";
            });

            //NOTE: here is how you consume the purchase after verifying it
            //Always consume the purchase if the purchase is consumable so it doesn't
            //get canceled

            //{uncomment this code}
            // final InAppPurchase inAppPurchase = InAppPurchase.instance;
            //
            // final InAppPurchaseAndroidPlatformAddition androidAddition = inAppPurchase
            //     .getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
            //
            // await androidAddition.consumePurchase(purchaseDetails);
          }

          //If current status of purchase is error we display the error and cancel execution
          if (purchaseDetails.status == PurchaseStatus.error) {
            //{Replace with your error handling}
            setState(() {
              purchaseStatus = "Error ${purchaseDetails.error}";
            });
            return;
          }

          //Here you verify your purchase with your backend. It is advised to do so
          //in the docs of the in app purchase package
          if (purchaseDetails.status == PurchaseStatus.purchased ||
              purchaseDetails.status == PurchaseStatus.restored) {
            //Here you verify the purchase
          }

          //IMPORTANT: if the status is pendingCompletePurchase that means that you need to complete
          //the purchase, otherwise the purchase will be canceled after few minutes
          //Make sure to always call instance.completePurchase(purchaseDetails)
          //to finalize the purchase.
          if (purchaseDetails.pendingCompletePurchase) {
            await InAppPurchase.instance.completePurchase(purchaseDetails);
            setState(() {
              purchaseStatus = "Success";
            });
          }
        },
      );
    } catch (e) {
      setState(() {
        purchaseStatus = "Error ${e.toString()}";
      });
    }
  }

  void showAlert(BuildContext context, Color bgColor, String message) {
    SnackBar snackBar = SnackBar(
      content: Text(message),
      backgroundColor: bgColor,
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'In App Purchase Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Builder(builder: (context) {
        return Scaffold(
          appBar: AppBar(
            title: Text("In App Purchase Example"),
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Platform available: ${isPlatformAvailable}"),
                const SizedBox(
                  height: 5,
                ),
                Text("Purchase status: ${purchaseStatus}"),
                const SizedBox(
                  height: 30,
                ),
                ElevatedButton(
                  //Pressing this button will start the process to buy the product
                  onPressed: () {
                    //Here you pass the IDs of the in app products you created in your Google Play Console
                    buyProduct({"your_product_id", "your_product_id"}, context);
                  },
                  child: Text("Make Purchase"),
                ),
                ElevatedButton(
                  //Pressing this button will start the process to buy the subscription
                  onPressed: () {
                    //Here you pass the IDs of the subscriptions you created in your Google Play Console
                    buySubscription({"your_subscription_id"}, context);
                  },
                  child: Text("Subscribe"),
                )
              ],
            ),
          ),
        );
      }),
    );
  }
}
