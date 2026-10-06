#include "tetris_core.h"

static int expect_row(
    const int *actual,
    const int *expected,
    int count
) {
    for (int index = 0; index < count; ++index) {
        if (actual[index] != expected[index]) {
            return index + 1;
        }
    }

    return 0;
}

int main(void) {
    int coefficients[10];

    int expected[10] = {
        15, -5, -5, -4, -4,
        -3, 2, 2, 1, 1
    };

    unsigned int pixels[96 * 160];

    if (mock_theta_shape_cell_count(1) != 2) {
        return 11;
    }

    if (mock_theta_shape_cell_count(2) != 6) {
        return 12;
    }

    if (mock_theta_shape_cell_count(3) != 10) {
        return 13;
    }

    if (mock_theta_shape_cell_count(4) != 14) {
        return 14;
    }

    if (mock_theta_shape_cell_count(5) != 18) {
        return 15;
    }

    mock_theta_blog_coefficients(
        5,
        coefficients,
        10
    );

    if (expect_row(
            coefficients,
            expected,
            10
        ) != 0) {
        return 20;
    }

    mock_theta_render_rgba(
        pixels,
        96,
        160,
        96,
        5,
        0
    );

    if (pixels[0] == 0u) {
        return 30;
    }

    return 0;
}
