<?php

namespace App\Http\Requests\Api\V1\Admin;

use Illuminate\Contracts\Validation\ValidationRule;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class StoreSellerRequest extends FormRequest
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
            'email' => ['required', 'string', 'email', 'max:150', Rule::unique('users', 'email')],
            'password' => ['required', 'string', 'min:8'],
            'phone' => ['nullable', 'string', 'max:20'],
            'canteen_name' => ['required', 'string', 'max:150'],
            'canteen_description' => ['nullable', 'string', 'max:2000'],
            'opening_hours' => ['nullable', 'array'],
        ];
    }
}
