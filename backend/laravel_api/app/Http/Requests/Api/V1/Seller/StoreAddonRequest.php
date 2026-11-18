<?php

namespace App\Http\Requests\Api\V1\Seller;

use Illuminate\Contracts\Validation\ValidationRule;
use Illuminate\Foundation\Http\FormRequest;

class StoreAddonRequest extends FormRequest
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
            'name' => ['required', 'string', 'max:100'],
            'price' => ['sometimes', 'numeric', 'min:0'],
            'selection_rule' => ['sometimes', 'in:OPTIONAL,REQUIRED'],
            'is_available' => ['sometimes', 'boolean'],
        ];
    }
}
