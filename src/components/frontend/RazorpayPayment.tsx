import React, { useEffect } from "react";

interface RazorpayPaymentProps {
  amount: number; // in INR
  onSuccess: (response: any) => void;
  onFailure: (error: any) => void;
}

const RazorpayPayment: React.FC<RazorpayPaymentProps> = ({
  amount,
  onSuccess,
  onFailure,
}) => {
  // Load Razorpay script dynamically
  useEffect(() => {
    const script = document.createElement("script");
    script.src = "https://checkout.razorpay.com/v1/checkout.js";
    script.async = true;
    document.body.appendChild(script);
    return () => {
      document.body.removeChild(script);
    };
  }, []);

  // Function to open Razorpay checkout
  const openRazorpay = () => {
    // Razorpay publishable key — single source of truth. Set
    // VITE_RAZORPAY_KEY in your .env / Vercel env to switch to live (rzp_live_*).
    // Falls back to the bundled TEST key so local dev works out of the box.
    const razorpayKey =
      (import.meta.env.VITE_RAZORPAY_KEY as string | undefined) ||
      "rzp_test_XUTODhUdMAshi6";

    const options = {
      key: razorpayKey,
      amount: amount * 100, // Razorpay expects amount in paise
      currency: "INR",
      name: "Aajoo Homes",
      description: "Booking Payment",
      image: "https://razorpay.com/favicon.png",
      handler: function (response: any) {
        onSuccess(response);
      },
      prefill: {
        name: "Guest User",
        email: "guest@example.com",
        contact: "9999999999",
      },
      notes: {
        booking_id: "BOOKING123",
      },
      theme: {
        color: "#1B2447",
      },
    };

    const rzp = new (window as any).Razorpay(options);
    rzp.on("payment.failed", function (response: any) {
      onFailure(response.error);
    });
    rzp.open();
  };

  return (
    <button
      onClick={openRazorpay}
      style={{ display: "none" }}
      id="hiddenRazorpayTrigger"
    >
      Hidden Razorpay Trigger
    </button>
  );
};

export default RazorpayPayment;
