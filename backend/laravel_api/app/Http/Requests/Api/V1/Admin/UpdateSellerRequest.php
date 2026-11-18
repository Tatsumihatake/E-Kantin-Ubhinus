<?php

namespace App\Http\Requests\Api\V1\Admin;

use Illuminate\Contracts\Validation\ValidationRule;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdateSellerRequest extends FormRequest
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
            'name' => ['sometimes', 'string', 'max:100'],
            'email' => [
                'sometimes', 'string', 'email', 'max:150',
                Rule::unique('users', 'email')->ignore($this->route('seller')),
            ],
            'password' => ['sometimes', 'nullable', 'string', 'min:8'],
            'phone' => ['sometimes', 'nullable', 'string', 'max:20'],
            'canteen_name' => ['sometimes', 'string', 'max:150'],
            'canteen_description' => ['sometimes', 'nullable', 'string', 'max:2000'],
            'opening_hours' => ['sometimes', 'nullable', 'array'],
            'is_open' => ['sometimes', 'boolean'],
        ];
    }
}
