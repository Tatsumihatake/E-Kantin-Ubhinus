<?php

namespace App\Http\Requests\Api\V1\Seller;

use Illuminate\Contracts\Validation\ValidationRule;
use Illuminate\Foundation\Http\FormRequest;

class UpdateCanteenRequest extends FormRequest
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
            'name' => ['sometimes', 'string', 'max:150'],
            'description' => ['sometimes', 'nullable', 'string', 'max:2000'],
            'opening_hours' => ['sometimes', 'array'],
            'is_open' => ['sometimes', 'boolean'],
            'image' => ['sometimes', 'nullable', 'image', 'mimes:jpg,jpeg,png,webp', 'max:2048'],
        ];
    }
}
