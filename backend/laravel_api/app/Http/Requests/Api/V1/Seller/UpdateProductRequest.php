<?php

namespace App\Http\Requests\Api\V1\Seller;

use Illuminate\Contracts\Validation\ValidationRule;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdateProductRequest extends FormRequest
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
            'price' => ['sometimes', 'numeric', 'min:0'],
            'category_id' => ['sometimes', 'nullable', 'uuid', Rule::exists('categories', 'id')],
            'is_available' => ['sometimes', 'boolean'],
            'image' => ['sometimes', 'nullable', 'image', 'mimes:jpg,jpeg,png,webp', 'max:2048'],
        ];
    }
}
