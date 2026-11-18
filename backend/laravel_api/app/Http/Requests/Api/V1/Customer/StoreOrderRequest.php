<?php

namespace App\Http\Requests\Api\V1\Customer;

use Illuminate\Contracts\Validation\ValidationRule;

class StoreOrderRequest extends PreviewOrderRequest
{
    /**
     * @return array<string, ValidationRule|array<mixed>|string>
     */
    public function rules(): array
    {
        return [
            ...parent::rules(),
            'idempotency_key' => ['nullable', 'string', 'max:100'],
        ];
    }
}
