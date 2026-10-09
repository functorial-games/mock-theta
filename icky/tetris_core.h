#ifndef MOCK_THETA_TETRIS_CORE_H
#define MOCK_THETA_TETRIS_CORE_H

#define MOCK_THETA_FACTOR_COUNT 5
#define MOCK_THETA_MAX_DEGREE 9
#define MOCK_THETA_MAX_SHAPE_CELLS 18
#define MOCK_THETA_MAX_TOTAL_CELLS 50

/* The mathematical state is a deterministic prefix of whole typed panels.
 * Cell diagrams are derived views, never independently movable state. */
struct mock_theta_game {
    int added_count;
    int active_pointer;
    int drag_start_y;
    int preview_offset_y;
    int reset_armed;
};

struct mock_theta_layout {
    int cell;
    int board_left;
    int source_top;
    int stack_bottom;
    int target_top;
    int target_bottom;
    int reset_left;
    int reset_top;
};

enum mock_theta_pointer_phase {
    MOCK_THETA_POINTER_DOWN,
    MOCK_THETA_POINTER_MOVE,
    MOCK_THETA_POINTER_UP,
    MOCK_THETA_POINTER_CANCEL
};

void mock_theta_reset(struct mock_theta_game *game);
void mock_theta_cancel(struct mock_theta_game *game);
int mock_theta_layout(int width, int height, struct mock_theta_layout *layout);
int mock_theta_pointer(
    struct mock_theta_game *game,
    int width, int height,
    enum mock_theta_pointer_phase phase,
    int pointer, int x, int y
);

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
