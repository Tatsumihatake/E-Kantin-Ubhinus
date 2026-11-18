<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class EnsureRole
{
    /**
     * @param  Closure(Request): (Response)  $next
     */
    public function handle(Request $request, Closure $next, string ...$roles): Response
    {
        $user = $request->user();

        if (! $user || ! $user->is_active) {
            return response()->json([
                'message' => 'Akun tidak aktif atau belum terautentikasi.',
            ], 403);
        }

        $allowedRoles = array_map('strtoupper', $roles);

        if (! in_array($user->role->value, $allowedRoles, true)) {
            return response()->json([
                'message' => 'Anda tidak memiliki kewenangan untuk mengakses fitur ini.',
            ], 403);
        }

        return $next($request);
    }
}
