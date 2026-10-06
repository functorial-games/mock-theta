#ifndef MOCK_THETA_TETRIS_CORE_H
#define MOCK_THETA_TETRIS_CORE_H

#define MOCK_THETA_FACTOR_COUNT 5
#define MOCK_THETA_MAX_DEGREE 9
#define MOCK_THETA_MAX_SHAPE_CELLS 18
#define MOCK_THETA_MAX_TOTAL_CELLS 50

int mock_theta_shape_cell_count(int factor);

int mock_theta_shape_cells(
    int factor,
    int capacity,
    int *degrees,
    int *signs,
    int *origins,
    int *branches
);

void mock_theta_sum_coefficients(
    int factor_count,
    const int *factors,
    int coefficient_count,
    int *coefficients
);

int mock_theta_blog_factor(int added_count);

void mock_theta_blog_coefficients(
    int added_count,
    int *coefficients,
    int coefficient_count
);

void mock_theta_render_rgba(
    unsigned int *pixels,
    int width,
    int height,
    int stride,
    int added_count,
    int preview_offset_y
);

#endif
