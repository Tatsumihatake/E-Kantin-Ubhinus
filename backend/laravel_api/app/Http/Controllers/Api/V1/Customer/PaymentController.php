<?php

namespace App\Http\Controllers\Api\V1\Customer;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Customer\SimulatePaymentRequest;
use App\Http\Resources\PaymentResource;
use App\Models\Order;
use App\Models\Payment;
use App\Services\PaymentService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class PaymentController extends Controller
{
    public function __construct(private readonly PaymentService $paymentService) {}

    public function store(Request $request, Order $order): JsonResponse
    {
        $payment = $this->paymentService->start($order, $request->user());

        return (new PaymentResource($payment))->response()->setStatusCode(201);
    }

    public function show(Request $request, Payment $payment): PaymentResource
    {
        $this->authorizeOwner($request, $payment);

        return new PaymentResource($payment->load('order'));
    }

    public function simulate(SimulatePaymentRequest $request, Payment $payment): PaymentResource
    {
        $this->authorizeOwner($request, $payment);

        $payment = $this->paymentService->simulate($payment, $request->validated('result'));

        return new PaymentResource($payment);
    }

    private function authorizeOwner(Request $request, Payment $payment): void
    {
        if ($payment->order->customer_id !== $request->user()->id) {
            abort(403, 'Anda tidak memiliki kewenangan untuk mengakses pembayaran ini.');
        }
    }
}
