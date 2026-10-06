#include "tetris_core.h"

static int minimum_int(int left, int right) {
    return left < right ? left : right;
}

static int maximum_int(int left, int right) {
    return left > right ? left : right;
}

static unsigned int rgba(
    unsigned int red,
    unsigned int green,
    unsigned int blue
) {
    return 0xff000000u | (blue << 16) | (green << 8) | red;
}

static unsigned int factor_color(int factor) {
    switch (factor) {
        case 5: return rgba(48u, 157u, 225u);
        case 4: return rgba(246u, 170u, 48u);
        case 3: return rgba(84u, 188u, 110u);
        case 2: return rgba(225u, 79u, 73u);
        case 1: return rgba(157u, 102u, 205u);
        default: return rgba(185u, 190u, 199u);
    }
}

int mock_theta_shape_cell_count(int factor) {
    if (factor < 1 || factor > MOCK_THETA_FACTOR_COUNT) {
        return 0;
    }

    return 4 * factor - 2;
}

static int emit_seed(
    int factor,
    int seed_degree,
    int seed_sign,
    int origin,
    int *index,
    int capacity,
    int *degrees,
    int *signs,
    int *origins,
    int *branches
) {
    if (*index + 2 > capacity) {
        return 0;
    }

    degrees[*index] = seed_degree;
    signs[*index] = seed_sign;
    origins[*index] = origin;
    branches[*index] = 0;
    *index += 1;

    degrees[*index] = seed_degree + factor;
    signs[*index] = -seed_sign;
    origins[*index] = origin;
    branches[*index] = 1;
    *index += 1;

    return 1;
}

int mock_theta_shape_cells(
    int factor,
    int capacity,
    int *degrees,
    int *signs,
    int *origins,
    int *branches
) {
    int index = 0;
    int expected = mock_theta_shape_cell_count(factor);

    if (expected == 0 ||
        capacity < expected ||
        degrees == 0 ||
        signs == 0 ||
        origins == 0 ||
        branches == 0) {
        return -expected;
    }

    if (!emit_seed(
            factor,
            0,
            1,
            0,
            &index,
            capacity,
            degrees,
            signs,
            origins,
            branches
        )) {
        return -expected;
    }

    for (int previous = 1; previous < factor; ++previous) {
        if (!emit_seed(
                factor,
                0,
                1,
                previous,
                &index,
                capacity,
                degrees,
                signs,
                origins,
                branches
            )) {
            return -expected;
        }

        if (!emit_seed(
                factor,
                previous,
                -1,
                previous,
                &index,
                capacity,
                degrees,
                signs,
                origins,
                branches
            )) {
            return -expected;
        }
    }

    return index;
}

void mock_theta_sum_coefficients(
    int factor_count,
    const int *factors,
    int coefficient_count,
    int *coefficients
) {
    int degrees[MOCK_THETA_MAX_SHAPE_CELLS];
    int signs[MOCK_THETA_MAX_SHAPE_CELLS];
    int origins[MOCK_THETA_MAX_SHAPE_CELLS];
    int branches[MOCK_THETA_MAX_SHAPE_CELLS];

    if (coefficients == 0 || coefficient_count <= 0) {
        return;
    }

    for (int degree = 0; degree < coefficient_count; ++degree) {
        coefficients[degree] = 0;
    }

    if (factors == 0 || factor_count <= 0) {
        return;
    }

    for (int factor_index = 0;
         factor_index < factor_count;
         ++factor_index) {
        int count = mock_theta_shape_cells(
            factors[factor_index],
            MOCK_THETA_MAX_SHAPE_CELLS,
            degrees,
            signs,
            origins,
            branches
        );

        if (count <= 0) {
            continue;
        }

        for (int cell = 0; cell < count; ++cell) {
            int degree = degrees[cell];

            if (degree >= 0 && degree < coefficient_count) {
                coefficients[degree] += signs[cell];
            }
        }
    }
}

int mock_theta_blog_factor(int added_count) {
    if (added_count < 0 ||
        added_count >= MOCK_THETA_FACTOR_COUNT) {
        return 0;
    }

    return MOCK_THETA_FACTOR_COUNT - added_count;
}

void mock_theta_blog_coefficients(
    int added_count,
    int *coefficients,
    int coefficient_count
) {
    int factors[MOCK_THETA_FACTOR_COUNT];
    int count = added_count;

    if (count < 0) {
        count = 0;
    }

    if (count > MOCK_THETA_FACTOR_COUNT) {
        count = MOCK_THETA_FACTOR_COUNT;
    }

    for (int index = 0; index < count; ++index) {
        factors[index] = MOCK_THETA_FACTOR_COUNT - index;
    }

    mock_theta_sum_coefficients(
        count,
        factors,
        coefficient_count,
        coefficients
    );
}

static void fill_rect(
    unsigned int *pixels,
    int width,
    int height,
    int stride,
    int left,
    int top,
    int right,
    int bottom,
    unsigned int color
) {
    left = maximum_int(0, left);
    top = maximum_int(0, top);
    right = minimum_int(width, right);
    bottom = minimum_int(height, bottom);

    for (int y = top; y < bottom; ++y) {
        unsigned int *row = pixels + y * stride;

        for (int x = left; x < right; ++x) {
            row[x] = color;
        }
    }
}

static void draw_sign(
    unsigned int *pixels,
    int width,
    int height,
    int stride,
    int left,
    int top,
    int cell,
    int sign
) {
    int thickness = maximum_int(1, cell / 8);
    int middle_x = left + cell / 2;
    int middle_y = top + cell / 2;
    int arm = maximum_int(2, cell / 4);
    unsigned int ink = rgba(246u, 247u, 249u);

    fill_rect(
        pixels,
        width,
        height,
        stride,
        middle_x - arm,
        middle_y - thickness / 2,
        middle_x + arm + 1,
        middle_y + (thickness + 1) / 2,
        ink
    );

    if (sign > 0) {
        fill_rect(
            pixels,
            width,
            height,
            stride,
            middle_x - thickness / 2,
            middle_y - arm,
            middle_x + (thickness + 1) / 2,
            middle_y + arm + 1,
            ink
        );
    }
}

static void draw_cell(
    unsigned int *pixels,
    int width,
    int height,
    int stride,
    int left,
    int top,
    int cell,
    int factor,
    int sign
) {
    unsigned int edge = rgba(18u, 22u, 29u);
    unsigned int color = factor_color(factor);

    fill_rect(
        pixels,
        width,
        height,
        stride,
        left,
        top,
        left + cell,
        top + cell,
        edge
    );

    fill_rect(
        pixels,
        width,
        height,
        stride,
        left + 2,
        top + 2,
        left + cell - 2,
        top + cell - 2,
        color
    );

    draw_sign(
        pixels,
        width,
        height,
        stride,
        left + 2,
        top + 2,
        cell - 4,
        sign
    );
}

static void draw_shape(
    unsigned int *pixels,
    int width,
    int height,
    int stride,
    int factor,
    int left,
    int top,
    int cell
) {
    int degrees[MOCK_THETA_MAX_SHAPE_CELLS];
    int signs[MOCK_THETA_MAX_SHAPE_CELLS];
    int origins[MOCK_THETA_MAX_SHAPE_CELLS];
    int branches[MOCK_THETA_MAX_SHAPE_CELLS];
    int levels[MOCK_THETA_MAX_DEGREE + 1];

    int count = mock_theta_shape_cells(
        factor,
        MOCK_THETA_MAX_SHAPE_CELLS,
        degrees,
        signs,
        origins,
        branches
    );

    for (int degree = 0;
         degree <= MOCK_THETA_MAX_DEGREE;
         ++degree) {
        levels[degree] = 0;
    }

    for (int index = 0; index < count; ++index) {
        int degree = degrees[index];
        int level = levels[degree]++;

        draw_cell(
            pixels,
            width,
            height,
            stride,
            left + degree * cell,
            top + level * cell,
            cell,
            factor,
            signs[index]
        );
    }
}

static void draw_added_stack(
    unsigned int *pixels,
    int width,
    int height,
    int stride,
    int added_count,
    int left,
    int bottom,
    int cell
) {
    int levels[MOCK_THETA_MAX_DEGREE + 1];
    int degrees[MOCK_THETA_MAX_SHAPE_CELLS];
    int signs[MOCK_THETA_MAX_SHAPE_CELLS];
    int origins[MOCK_THETA_MAX_SHAPE_CELLS];
    int branches[MOCK_THETA_MAX_SHAPE_CELLS];

    for (int degree = 0;
         degree <= MOCK_THETA_MAX_DEGREE;
         ++degree) {
        levels[degree] = 0;
    }

    for (int added = 0; added < added_count; ++added) {
        int factor = mock_theta_blog_factor(added);

        int count = mock_theta_shape_cells(
            factor,
            MOCK_THETA_MAX_SHAPE_CELLS,
            degrees,
            signs,
            origins,
            branches
        );

        for (int index = 0; index < count; ++index) {
            int degree = degrees[index];
            int level = levels[degree]++;

            draw_cell(
                pixels,
                width,
                height,
                stride,
                left + degree * cell,
                bottom - (level + 1) * cell,
                cell,
                factor,
                signs[index]
            );
        }
    }
}

static void draw_arrow_down(
    unsigned int *pixels,
    int width,
    int height,
    int stride,
    int center_x,
    int top,
    int bottom
) {
    int thickness = maximum_int(2, width / 160);
    int head = maximum_int(8, width / 28);
    unsigned int color = rgba(220u, 72u, 67u);

    if (bottom <= top + head) {
        return;
    }

    fill_rect(
        pixels,
        width,
        height,
        stride,
        center_x - thickness / 2,
        top,
        center_x + (thickness + 1) / 2,
        bottom - head,
        color
    );

    for (int step = 0; step < head; ++step) {
        int half = step;

        fill_rect(
            pixels,
            width,
            height,
            stride,
            center_x - half,
            bottom - head + step,
            center_x + half + 1,
            bottom - head + step + 1,
            color
        );
    }
}

static const unsigned char digit_rows[11][5] = {
    {7,5,5,5,7},
    {2,6,2,2,7},
    {7,1,7,4,7},
    {7,1,7,1,7},
    {5,5,7,1,1},
    {7,4,7,1,7},
    {7,4,7,5,7},
    {7,1,1,1,1},
    {7,5,7,5,7},
    {7,5,7,1,7},
    {0,0,7,0,0}
};

static void draw_digit(
    unsigned int *pixels,
    int width,
    int height,
    int stride,
    int x,
    int y,
    int scale,
    int digit,
    unsigned int color
) {
    if (digit < 0 || digit > 10) {
        return;
    }

    for (int row = 0; row < 5; ++row) {
        unsigned char bits = digit_rows[digit][row];

        for (int column = 0; column < 3; ++column) {
            if ((bits & (1u << (2 - column))) != 0u) {
                fill_rect(
                    pixels,
                    width,
                    height,
                    stride,
                    x + column * scale,
                    y + row * scale,
                    x + (column + 1) * scale,
                    y + (row + 1) * scale,
                    color
                );
            }
        }
    }
}

static void draw_integer_centered(
    unsigned int *pixels,
    int width,
    int height,
    int stride,
    int center_x,
    int y,
    int scale,
    int value,
    unsigned int color
) {
    int negative = value < 0;
    int magnitude = negative ? -value : value;
    int tens = magnitude / 10;
    int ones = magnitude % 10;
    int glyphs =
        1 +
        (tens > 0 ? 1 : 0) +
        (negative ? 1 : 0);
    int glyph_width = 4 * scale;
    int x =
        center_x -
        (glyphs * glyph_width - scale) / 2;

    if (negative) {
        draw_digit(
            pixels,
            width,
            height,
            stride,
            x,
            y,
            scale,
            10,
            color
        );
        x += glyph_width;
    }

    if (tens > 0) {
        draw_digit(
            pixels,
            width,
            height,
            stride,
            x,
            y,
            scale,
            tens,
            color
        );
        x += glyph_width;
    }

    draw_digit(
        pixels,
        width,
        height,
        stride,
        x,
        y,
        scale,
        ones,
        color
    );
}

void mock_theta_render_rgba(
    unsigned int *pixels,
    int width,
    int height,
    int stride,
    int added_count,
    int preview_offset_y
) {
    int coefficients[MOCK_THETA_MAX_DEGREE + 1];
    int cell;
    int board_left;
    int source_top;
    int stack_bottom;
    int source_factor;

    unsigned int background = rgba(8u, 10u, 14u);
    unsigned int guide = rgba(57u, 63u, 74u);
    unsigned int coefficient_color =
        rgba(231u, 235u, 242u);

    if (pixels == 0 ||
        width <= 0 ||
        height <= 0 ||
        stride < width) {
        return;
    }

    if (added_count < 0) {
        added_count = 0;
    }

    if (added_count > MOCK_THETA_FACTOR_COUNT) {
        added_count = MOCK_THETA_FACTOR_COUNT;
    }

    fill_rect(
        pixels,
        width,
        height,
        stride,
        0,
        0,
        width,
        height,
        background
    );

    cell = minimum_int(width / 12, height / 34);
    cell = maximum_int(14, cell);

    board_left =
        (width -
         (MOCK_THETA_MAX_DEGREE + 1) * cell) / 2;

    source_top =
        maximum_int(28, height / 18) +
        preview_offset_y;

    stack_bottom =
        height -
        maximum_int(72, height / 13);

    for (int degree = 0;
         degree <= MOCK_THETA_MAX_DEGREE;
         ++degree) {
        int x = board_left + degree * cell;

        fill_rect(
            pixels,
            width,
            height,
            stride,
            x,
            stack_bottom,
            x + cell - 1,
            stack_bottom + 2,
            guide
        );
    }

    draw_added_stack(
        pixels,
        width,
        height,
        stride,
        added_count,
        board_left,
        stack_bottom,
        cell
    );

    source_factor =
        mock_theta_blog_factor(added_count);

    if (source_factor != 0) {
        draw_shape(
            pixels,
            width,
            height,
            stride,
            source_factor,
            board_left,
            source_top,
            cell
        );

        if (preview_offset_y == 0) {
            int arrow_top =
                source_top +
                (source_factor + 1) * cell;

            int arrow_bottom =
                maximum_int(
                    arrow_top + cell,
                    height / 2
                );

            draw_arrow_down(
                pixels,
                width,
                height,
                stride,
                width / 2,
                arrow_top,
                arrow_bottom
            );
        }
    }

    mock_theta_blog_coefficients(
        added_count,
        coefficients,
        MOCK_THETA_MAX_DEGREE + 1
    );

    {
        int scale =
            maximum_int(1, cell / 12);

        int y =
            stack_bottom +
            maximum_int(12, cell / 3);

        for (int degree = 0;
             degree <= MOCK_THETA_MAX_DEGREE;
             ++degree) {
            draw_integer_centered(
                pixels,
                width,
                height,
                stride,
                board_left +
                    degree * cell +
                    cell / 2,
                y,
                scale,
                coefficients[degree],
                coefficient_color
            );
        }
    }
}
