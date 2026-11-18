<?php

namespace App\Http\Requests\Api\V1\Customer;

use Illuminate\Contracts\Validation\ValidationRule;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class PreviewOrderRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    /**
     * @return array<string, ValidationRule|array<mixed>|string>
     */
    public function rules(): array
    {
        return [
            'product_id' => ['required', 'uuid', Rule::exists('products', 'id')],
            'quantity' => ['required', 'integer', 'min:1'],
            'addon_ids' => ['nullable', 'array'],
            'addon_ids.*' => ['uuid', 'distinct', Rule::exists('addons', 'id')],
            'request' => ['nullable', 'string', 'max:500'],
        ];
    }
}
