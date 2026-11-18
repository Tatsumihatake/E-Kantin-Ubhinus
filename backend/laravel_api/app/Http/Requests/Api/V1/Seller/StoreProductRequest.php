<?php

namespace App\Http\Requests\Api\V1\Seller;

use Illuminate\Contracts\Validation\ValidationRule;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class StoreProductRequest extends FormRequest
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
            'name' => ['required', 'string', 'max:150'],
            'description' => ['nullable', 'string', 'max:2000'],
            'price' => ['required', 'numeric', 'min:0'],
            'category_id' => ['nullable', 'uuid', Rule::exists('categories', 'id')],
            'is_available' => ['sometimes', 'boolean'],
            'image' => ['nullable', 'image', 'mimes:jpg,jpeg,png,webp', 'max:2048'],
        ];
    }
}
