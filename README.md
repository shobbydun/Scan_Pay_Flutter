# Scan_Pay App

**Scan_Pay** is a mobile application designed to enhance the shopping experience by allowing customers to scan products, pay directly through the app, and leave the supermarket without waiting in long queues. This app is ideal for users who want to save time and avoid traditional checkout lines.

## Features

- **Product Scanning**: Scan product barcodes using your phone’s camera.
- **Instant Pricing**: View real-time prices of items as you scan them.
- **Secure Payment**: Pay for your items directly through the app using various payment methods (e.g., M-Pesa, PayPal, Visa).
- **Transaction History**: Keep track of your purchases and payment history.
- **No Queues**: Once you’ve completed your payment, simply exit the supermarket—no need to wait in line.
- **Seamless User Experience**: Simple and intuitive interface for quick and easy shopping.

## Installation

1. Clone the repository:

    ```bash
    git clone https://github.com/yourusername/scan_pay.git
    ```

2. Navigate to the project directory:

    ```bash
    cd scan_pay
    ```

3. Install dependencies:

    For **Flutter**:

    ```bash
    flutter pub get
    ```

4. Set up Firebase (for cart, authentication, and transaction management):
   - Follow the [Firebase setup guide for Flutter](https://firebase.flutter.dev/docs/overview) to configure Firebase for your app.
   - Ensure that you have added Firebase Authentication, Firestore, and other required services in the Firebase console.
   
5. Run the app:

    ```bash
    flutter run
    ```

## How It Works

1. **Scanning Products**: 
   - Open the app and use the built-in barcode scanner to scan the products you wish to purchase.
   - As you scan items, their prices will be displayed on your screen in real time.
   
2. **View Cart & Total**:
   - After scanning all the desired products, the app will display the total amount.
   - You can adjust quantities or remove items from your cart as needed.
   
3. **Make Payment**:
   - Once you're ready to checkout, tap the **Checkout** button.
   - Select your preferred payment method (e.g., M-Pesa, PayPal, Visa).
   - Enter any required payment details, such as M-Pesa PIN or PayPal credentials.
   - The app will process the payment and confirm the transaction.
   
4. **Exit the Supermarket**:
   - Once payment is successful, simply exit the store.
   - You will receive a digital receipt via email or within the app.
   
5. **Transaction History**:
   - You can access your past transactions and receipts from the app’s history section.

# ScreenShots

![Image](https://github.com/user-attachments/assets/b17b9b84-0069-4cef-8221-6d0e7aaee5a1)
![Image](https://github.com/user-attachments/assets/44b33558-e137-42fb-86a7-c35c1ec67db1)
![Image](https://github.com/user-attachments/assets/6a77054a-9c6a-42e0-88c1-8eeb45f8f307)
![Image](https://github.com/user-attachments/assets/e0500b2f-bc26-483b-8701-15f54383ec9c)
![Image](https://github.com/user-attachments/assets/9c4bbaee-7ef4-4747-8d7a-6ffcbc62fbcb)
![Image](https://github.com/user-attachments/assets/c17d41a1-7631-44ec-b369-b41117d2a0f2)
![Image](https://github.com/user-attachments/assets/9e962174-e143-43e1-aea0-f7e2e874109d)
![Image](https://github.com/user-attachments/assets/89ef112e-3829-4538-8fa6-4683987d46c5)
![Image](https://github.com/user-attachments/assets/a21cd6fb-fe6d-4d31-b9a1-1e7e71630238)

