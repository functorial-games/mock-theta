#include <android/input.h>
#include <android/log.h>
#include <android/native_window.h>
#include <android_native_app_glue.h>

#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <time.h>

#define LOG_TAG "MockThetaTetris"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)

#define BOARD_WIDTH 10
#define BOARD_HEIGHT 16
#define CELLS_PER_PIECE 4
#define SHAPE_COUNT 7
#define FACTOR_COUNT 4
#define MAX_TERM_INDEX 8
#define GRAVITY_MILLIS 520

struct board_cell {
    uint8_t occupied;
    uint8_t factor;
    int8_t sign;
};

struct falling_piece {
    int shape;
    int rotation;
    int grid_x;
    int grid_y;
    int factor;
    int term_index;
};

struct rect {
    int left;
    int top;
    int right;
    int bottom;
};

struct layout {
    int cell;
    int board_left;
    int board_top;
    int board_width_pixels;
    int board_height_pixels;
    struct rect previous_button;
    struct rect next_button;
    struct rect drop_button;
};

enum touch_target {
    TARGET_NONE = 0,
    TARGET_PIECE,
    TARGET_PREVIOUS,
    TARGET_NEXT,
    TARGET_DROP
};

struct game_state {
    struct android_app *app;
    struct board_cell board[BOARD_HEIGHT][BOARD_WIDTH];
    struct falling_piece active;

    bool window_ready;
    bool has_focus;
    bool have_active_piece;
    bool redraw;

    int surface_width;
    int surface_height;
    int piece_serial;

    int current_path_degree;
    int64_t current_path_coefficient;
    int last_path_degree;
    int64_t last_path_coefficient;
    int completed_paths;

    enum touch_target touch_target;
    bool touch_moved;
    float down_x;
    float down_y;
    float last_x;
    float last_y;
    int grab_offset_x;
    int grab_offset_y;
    int64_t down_time_millis;
    int64_t last_gravity_millis;
};

static const int8_t BASE_SHAPES[SHAPE_COUNT][CELLS_PER_PIECE][2] = {
    { {0, 0}, {1, 0}, {2, 0}, {3, 0} },
    { {0, 0}, {1, 0}, {0, 1}, {1, 1} },
    { {0, 0}, {1, 0}, {2, 0}, {1, 1} },
    { {1, 0}, {2, 0}, {0, 1}, {1, 1} },
    { {0, 0}, {1, 0}, {1, 1}, {2, 1} },
    { {0, 0}, {0, 1}, {1, 1}, {2, 1} },
    { {2, 0}, {0, 1}, {1, 1}, {2, 1} }
};

struct glyph {
    char character;
    uint8_t rows[7];
};

static const struct glyph FONT[] = {
    {'A', {14,17,17,31,17,17,17}},
    {'C', {14,17,16,16,16,17,14}},
    {'D', {30,17,17,17,17,17,30}},
    {'E', {31,16,16,30,16,16,31}},
    {'F', {31,16,16,30,16,16,16}},
    {'H', {17,17,17,31,17,17,17}},
    {'I', {31,4,4,4,4,4,31}},
    {'K', {17,18,20,24,20,18,17}},
    {'L', {16,16,16,16,16,16,31}},
    {'M', {17,27,21,21,17,17,17}},
    {'N', {17,25,21,19,17,17,17}},
    {'O', {14,17,17,17,17,17,14}},
    {'P', {30,17,17,30,16,16,16}},
    {'Q', {14,17,17,17,21,18,13}},
    {'R', {30,17,17,30,20,18,17}},
    {'S', {15,16,16,14,1,1,30}},
    {'T', {31,4,4,4,4,4,4}},
    {'U', {17,17,17,17,17,17,14}},
    {'V', {17,17,17,17,17,10,4}},
    {'X', {17,17,10,4,10,17,17}},
    {'0', {14,17,19,21,25,17,14}},
    {'1', {4,12,4,4,4,4,14}},
    {'2', {14,17,1,2,4,8,31}},
    {'3', {30,1,1,14,1,1,30}},
    {'4', {2,6,10,18,31,2,2}},
    {'5', {31,16,16,30,1,1,30}},
    {'6', {14,16,16,30,17,17,14}},
    {'7', {31,1,2,4,8,8,8}},
    {'8', {14,17,17,14,17,17,14}},
    {'9', {14,17,17,15,1,1,14}},
    {'+', {0,4,4,31,4,4,0}},
    {'-', {0,0,0,31,0,0,0}},
    {'^', {4,10,17,0,0,0,0}},
    {' ', {0,0,0,0,0,0,0}}
};

static int64_t now_millis(void) {
    struct timespec time_value;
    clock_gettime(CLOCK_MONOTONIC, &time_value);
    return (int64_t)time_value.tv_sec * 1000LL +
           (int64_t)time_value.tv_nsec / 1000000LL;
}

static uint32_t rgba(uint8_t red, uint8_t green, uint8_t blue) {
    return 0xff000000u |
           ((uint32_t)blue << 16) |
           ((uint32_t)green << 8) |
           (uint32_t)red;
}

static uint32_t factor_color(int factor, bool active) {
    static const uint8_t colors[FACTOR_COUNT][3] = {
        {51, 196, 255},
        {255, 90, 190},
        {255, 211, 67},
        {98, 222, 126}
    };
    int index = factor - 1;
    if (index < 0 || index >= FACTOR_COUNT) {
        index = 0;
    }

    uint8_t red = colors[index][0];
    uint8_t green = colors[index][1];
    uint8_t blue = colors[index][2];

    if (!active) {
        red = (uint8_t)(red * 3 / 4);
        green = (uint8_t)(green * 3 / 4);
        blue = (uint8_t)(blue * 3 / 4);
    }

    return rgba(red, green, blue);
}

static int term_degree(const struct falling_piece *piece) {
    return piece->factor * piece->term_index;
}

static int term_coefficient(const struct falling_piece *piece) {
    int magnitude = piece->term_index + 1;
    return (piece->term_index % 2 == 0) ? magnitude : -magnitude;
}

static int minimum_int(int left, int right) {
    return left < right ? left : right;
}

static int maximum_int(int left, int right) {
    return left > right ? left : right;
}

static int absolute_int(int value) {
    return value < 0 ? -value : value;
}

static struct layout make_layout(int width, int height) {
    struct layout result;
    int horizontal_margin = maximum_int(12, width / 30);
    int hud_height = maximum_int(92, height / 11);
    int controls_height = maximum_int(96, height / 9);
    int available_height = height - hud_height - controls_height - 24;
    int cell_from_width = (width - horizontal_margin * 2) / BOARD_WIDTH;
    int cell_from_height = available_height / BOARD_HEIGHT;

    result.cell = minimum_int(cell_from_width, cell_from_height);
    if (result.cell < 10) {
        result.cell = 10;
    }

    result.board_width_pixels = result.cell * BOARD_WIDTH;
    result.board_height_pixels = result.cell * BOARD_HEIGHT;
    result.board_left = (width - result.board_width_pixels) / 2;
    result.board_top = hud_height;

    int button_gap = maximum_int(6, result.cell / 5);
    int button_top = result.board_top + result.board_height_pixels + button_gap;
    int button_height = maximum_int(48, height - button_top - button_gap);
    int button_width =
        (result.board_width_pixels - button_gap * 2) / 3;

    result.previous_button = (struct rect) {
        result.board_left,
        button_top,
        result.board_left + button_width,
        button_top + button_height
    };
    result.next_button = (struct rect) {
        result.board_left + button_width + button_gap,
        button_top,
        result.board_left + button_width * 2 + button_gap,
        button_top + button_height
    };
    result.drop_button = (struct rect) {
        result.board_left + button_width * 2 + button_gap * 2,
        button_top,
        result.board_left + result.board_width_pixels,
        button_top + button_height
    };

    return result;
}

static bool point_in_rect(float x, float y, struct rect rectangle) {
    return x >= (float)rectangle.left &&
           x < (float)rectangle.right &&
           y >= (float)rectangle.top &&
           y < (float)rectangle.bottom;
}

static void piece_cells(
    const struct falling_piece *piece,
    int output[CELLS_PER_PIECE][2]
) {
    int min_x = 100;
    int min_y = 100;
    int transformed[CELLS_PER_PIECE][2];

    for (int index = 0; index < CELLS_PER_PIECE; ++index) {
        int x = BASE_SHAPES[piece->shape][index][0];
        int y = BASE_SHAPES[piece->shape][index][1];

        for (int turn = 0; turn < piece->rotation; ++turn) {
            int rotated_x = -y;
            int rotated_y = x;
            x = rotated_x;
            y = rotated_y;
        }

        transformed[index][0] = x;
        transformed[index][1] = y;
        if (x < min_x) {
            min_x = x;
        }
        if (y < min_y) {
            min_y = y;
        }
    }

    for (int index = 0; index < CELLS_PER_PIECE; ++index) {
        output[index][0] =
            piece->grid_x + transformed[index][0] - min_x;
        output[index][1] =
            piece->grid_y + transformed[index][1] - min_y;
    }
}

static bool can_place(
    const struct game_state *state,
    const struct falling_piece *piece
) {
    int cells[CELLS_PER_PIECE][2];
    piece_cells(piece, cells);

    for (int index = 0; index < CELLS_PER_PIECE; ++index) {
        int x = cells[index][0];
        int y = cells[index][1];

        if (x < 0 || x >= BOARD_WIDTH ||
            y < 0 || y >= BOARD_HEIGHT) {
            return false;
        }
        if (state->board[y][x].occupied != 0) {
            return false;
        }
    }

    return true;
}

static void clear_board(struct game_state *state) {
    memset(state->board, 0, sizeof(state->board));
    state->current_path_degree = 0;
    state->current_path_coefficient = 1;
    state->last_path_degree = 0;
    state->last_path_coefficient = 0;
    state->completed_paths = 0;
}

static void spawn_piece(struct game_state *state) {
    struct falling_piece piece;
    memset(&piece, 0, sizeof(piece));

    piece.shape = state->piece_serial % SHAPE_COUNT;
    piece.rotation = 0;
    piece.grid_x = 3;
    piece.grid_y = 0;
    piece.factor = (state->piece_serial % FACTOR_COUNT) + 1;
    piece.term_index = 1;

    if (!can_place(state, &piece)) {
        LOGI("top out: preserving no stale board state");
        clear_board(state);
    }

    state->active = piece;
    state->have_active_piece = true;
    state->redraw = true;
}

static void finish_path_if_needed(struct game_state *state) {
    if (state->active.factor != FACTOR_COUNT) {
        return;
    }

    state->last_path_degree = state->current_path_degree;
    state->last_path_coefficient = state->current_path_coefficient;
    state->completed_paths += 1;

    LOGI(
        "completed denominator path: q^%d coefficient=%lld",
        state->last_path_degree,
        (long long)state->last_path_coefficient
    );

    state->current_path_degree = 0;
    state->current_path_coefficient = 1;
}

static void lock_active_piece(struct game_state *state) {
    if (!state->have_active_piece) {
        return;
    }

    int cells[CELLS_PER_PIECE][2];
    piece_cells(&state->active, cells);
    int coefficient = term_coefficient(&state->active);
    int sign = coefficient < 0 ? -1 : 1;

    for (int index = 0; index < CELLS_PER_PIECE; ++index) {
        int x = cells[index][0];
        int y = cells[index][1];
        if (x < 0 || x >= BOARD_WIDTH ||
            y < 0 || y >= BOARD_HEIGHT) {
            continue;
        }

        state->board[y][x].occupied = 1;
        state->board[y][x].factor = (uint8_t)state->active.factor;
        state->board[y][x].sign = (int8_t)sign;
    }

    state->current_path_degree += term_degree(&state->active);
    state->current_path_coefficient *= (int64_t)coefficient;
    finish_path_if_needed(state);

    state->piece_serial += 1;
    state->have_active_piece = false;
    spawn_piece(state);
}

static bool try_translate(
    struct game_state *state,
    int delta_x,
    int delta_y
) {
    if (!state->have_active_piece) {
        return false;
    }

    struct falling_piece candidate = state->active;
    candidate.grid_x += delta_x;
    candidate.grid_y += delta_y;

    if (!can_place(state, &candidate)) {
        return false;
    }

    state->active = candidate;
    state->redraw = true;
    return true;
}

static void move_toward(
    struct game_state *state,
    int target_x,
    int target_y
) {
    target_x = maximum_int(-3, minimum_int(BOARD_WIDTH + 2, target_x));
    target_y = maximum_int(0, minimum_int(BOARD_HEIGHT - 1, target_y));

    int guard = 0;
    while (state->active.grid_x != target_x && guard++ < BOARD_WIDTH * 2) {
        int step = state->active.grid_x < target_x ? 1 : -1;
        if (!try_translate(state, step, 0)) {
            break;
        }
    }

    guard = 0;
    while (state->active.grid_y != target_y && guard++ < BOARD_HEIGHT * 2) {
        int step = state->active.grid_y < target_y ? 1 : -1;
        if (!try_translate(state, 0, step)) {
            break;
        }
    }
}

static void rotate_active_piece(struct game_state *state) {
    if (!state->have_active_piece) {
        return;
    }

    struct falling_piece candidate = state->active;
    candidate.rotation = (candidate.rotation + 1) % 4;
    if (can_place(state, &candidate)) {
        state->active = candidate;
        state->redraw = true;
    }
}

static void hard_drop(struct game_state *state) {
    if (!state->have_active_piece) {
        return;
    }

    while (try_translate(state, 0, 1)) {
    }
    lock_active_piece(state);
}

static void gravity_step(struct game_state *state) {
    if (!state->have_active_piece) {
        spawn_piece(state);
        return;
    }

    if (!try_translate(state, 0, 1)) {
        lock_active_piece(state);
    }
}

static const uint8_t *glyph_rows(char character) {
    for (size_t index = 0; index < sizeof(FONT) / sizeof(FONT[0]); ++index) {
        if (FONT[index].character == character) {
            return FONT[index].rows;
        }
    }
    return FONT[sizeof(FONT) / sizeof(FONT[0]) - 1].rows;
}

static void fill_rect(
    uint32_t *pixels,
    int width,
    int height,
    int stride,
    struct rect rectangle,
    uint32_t color
) {
    int left = maximum_int(0, rectangle.left);
    int top = maximum_int(0, rectangle.top);
    int right = minimum_int(width, rectangle.right);
    int bottom = minimum_int(height, rectangle.bottom);

    for (int y = top; y < bottom; ++y) {
        uint32_t *row = pixels + y * stride;
        for (int x = left; x < right; ++x) {
            row[x] = color;
        }
    }
}

static void draw_char(
    uint32_t *pixels,
    int width,
    int height,
    int stride,
    int x,
    int y,
    int scale,
    char character,
    uint32_t color
) {
    const uint8_t *rows = glyph_rows(character);

    for (int row = 0; row < 7; ++row) {
        for (int column = 0; column < 5; ++column) {
            if ((rows[row] & (1u << (4 - column))) == 0) {
                continue;
            }

            fill_rect(
                pixels,
                width,
                height,
                stride,
                (struct rect) {
                    x + column * scale,
                    y + row * scale,
                    x + (column + 1) * scale,
                    y + (row + 1) * scale
                },
                color
            );
        }
    }
}

static int text_width(const char *text, int scale) {
    return (int)strlen(text) * 6 * scale;
}

static void draw_text(
    uint32_t *pixels,
    int width,
    int height,
    int stride,
    int x,
    int y,
    int scale,
    const char *text,
    uint32_t color
) {
    int cursor = x;
    for (const char *character = text; *character != '\0'; ++character) {
        draw_char(
            pixels,
            width,
            height,
            stride,
            cursor,
            y,
            scale,
            *character,
            color
        );
        cursor += 6 * scale;
    }
}

static void draw_text_centered(
    uint32_t *pixels,
    int width,
    int height,
    int stride,
    int y,
    int scale,
    const char *text,
    uint32_t color
) {
    int x = (width - text_width(text, scale)) / 2;
    draw_text(pixels, width, height, stride, x, y, scale, text, color);
}

static void draw_button(
    uint32_t *pixels,
    int width,
    int height,
    int stride,
    struct rect rectangle,
    const char *label
) {
    uint32_t body = rgba(38, 42, 50);
    uint32_t edge = rgba(105, 113, 128);
    uint32_t text = rgba(235, 239, 246);

    fill_rect(pixels, width, height, stride, rectangle, edge);
    struct rect inner = {
        rectangle.left + 2,
        rectangle.top + 2,
        rectangle.right - 2,
        rectangle.bottom - 2
    };
    fill_rect(pixels, width, height, stride, inner, body);

    int scale = maximum_int(
        1,
        minimum_int(3, (rectangle.right - rectangle.left) / 42)
    );
    int x = (rectangle.left + rectangle.right - text_width(label, scale)) / 2;
    int y = (rectangle.top + rectangle.bottom - 7 * scale) / 2;
    draw_text(pixels, width, height, stride, x, y, scale, label, text);
}

static void draw_board(
    struct game_state *state,
    uint32_t *pixels,
    int width,
    int height,
    int stride,
    struct layout layout
) {
    uint32_t grid_background = rgba(13, 16, 22);
    uint32_t grid_line = rgba(42, 47, 58);

    fill_rect(
        pixels,
        width,
        height,
        stride,
        (struct rect) {
            layout.board_left - 2,
            layout.board_top - 2,
            layout.board_left + layout.board_width_pixels + 2,
            layout.board_top + layout.board_height_pixels + 2
        },
        grid_line
    );

    fill_rect(
        pixels,
        width,
        height,
        stride,
        (struct rect) {
            layout.board_left,
            layout.board_top,
            layout.board_left + layout.board_width_pixels,
            layout.board_top + layout.board_height_pixels
        },
        grid_background
    );

    for (int board_y = 0; board_y < BOARD_HEIGHT; ++board_y) {
        for (int board_x = 0; board_x < BOARD_WIDTH; ++board_x) {
            struct rect cell_rect = {
                layout.board_left + board_x * layout.cell + 1,
                layout.board_top + board_y * layout.cell + 1,
                layout.board_left + (board_x + 1) * layout.cell - 1,
                layout.board_top + (board_y + 1) * layout.cell - 1
            };

            if (state->board[board_y][board_x].occupied != 0) {
                uint32_t color = factor_color(
                    state->board[board_y][board_x].factor,
                    false
                );
                fill_rect(
                    pixels,
                    width,
                    height,
                    stride,
                    cell_rect,
                    color
                );

                if (state->board[board_y][board_x].sign < 0) {
                    int stripe = maximum_int(2, layout.cell / 8);
                    fill_rect(
                        pixels,
                        width,
                        height,
                        stride,
                        (struct rect) {
                            cell_rect.left,
                            cell_rect.top,
                            cell_rect.left + stripe,
                            cell_rect.bottom
                        },
                        rgba(255, 255, 255)
                    );
                }
            } else if (layout.cell >= 18) {
                fill_rect(
                    pixels,
                    width,
                    height,
                    stride,
                    (struct rect) {
                        cell_rect.left,
                        cell_rect.bottom - 1,
                        cell_rect.right,
                        cell_rect.bottom
                    },
                    rgba(20, 24, 31)
                );
            }
        }
    }

    if (!state->have_active_piece) {
        return;
    }

    int cells[CELLS_PER_PIECE][2];
    piece_cells(&state->active, cells);
    uint32_t color = factor_color(state->active.factor, true);

    for (int index = 0; index < CELLS_PER_PIECE; ++index) {
        int board_x = cells[index][0];
        int board_y = cells[index][1];

        struct rect cell_rect = {
            layout.board_left + board_x * layout.cell + 2,
            layout.board_top + board_y * layout.cell + 2,
            layout.board_left + (board_x + 1) * layout.cell - 2,
            layout.board_top + (board_y + 1) * layout.cell - 2
        };

        fill_rect(
            pixels,
            width,
            height,
            stride,
            cell_rect,
            color
        );

        if (term_coefficient(&state->active) < 0) {
            int stripe = maximum_int(2, layout.cell / 8);
            fill_rect(
                pixels,
                width,
                height,
                stride,
                (struct rect) {
                    cell_rect.left,
                    cell_rect.top,
                    cell_rect.left + stripe,
                    cell_rect.bottom
                },
                rgba(255, 255, 255)
            );
        }
    }
}

static void draw_hud(
    struct game_state *state,
    uint32_t *pixels,
    int width,
    int height,
    int stride
) {
    int scale = width >= 480 ? 2 : 1;
    uint32_t main_text = rgba(235, 239, 246);
    uint32_t status_text = rgba(255, 181, 71);
    char term_line[64];
    char path_line[64];

    draw_text_centered(
        pixels, width, height, stride,
        8, scale, "MOCK THETA TETRIS", main_text
    );

    draw_text_centered(
        pixels, width, height, stride,
        10 + 9 * scale, scale,
        "SERIES UNVERIFIED",
        status_text
    );

    if (state->have_active_piece) {
        int coefficient = term_coefficient(&state->active);
        snprintf(
            term_line,
            sizeof(term_line),
            "M%d K%d Q^%d C%+d",
            state->active.factor,
            state->active.term_index,
            term_degree(&state->active),
            coefficient
        );
        draw_text_centered(
            pixels, width, height, stride,
            12 + 18 * scale, scale,
            term_line,
            factor_color(state->active.factor, true)
        );
    }

    if (state->completed_paths > 0) {
        snprintf(
            path_line,
            sizeof(path_line),
            "PATH Q^%d C%+lld",
            state->last_path_degree,
            (long long)state->last_path_coefficient
        );
        draw_text_centered(
            pixels, width, height, stride,
            14 + 27 * scale, scale,
            path_line,
            rgba(174, 184, 201)
        );
    }
}

static void draw_frame(struct game_state *state) {
    if (!state->window_ready || state->app->window == NULL) {
        return;
    }

    ANativeWindow_Buffer buffer;
    if (ANativeWindow_lock(state->app->window, &buffer, NULL) != 0) {
        return;
    }

    state->surface_width = buffer.width;
    state->surface_height = buffer.height;
    struct layout layout = make_layout(buffer.width, buffer.height);

    uint32_t *pixels = (uint32_t *)buffer.bits;
    fill_rect(
        pixels,
        buffer.width,
        buffer.height,
        buffer.stride,
        (struct rect) {0, 0, buffer.width, buffer.height},
        rgba(7, 9, 13)
    );

    draw_hud(
        state,
        pixels,
        buffer.width,
        buffer.height,
        buffer.stride
    );
    draw_board(
        state,
        pixels,
        buffer.width,
        buffer.height,
        buffer.stride,
        layout
    );

    draw_button(
        pixels, buffer.width, buffer.height, buffer.stride,
        layout.previous_button, "PREV"
    );
    draw_button(
        pixels, buffer.width, buffer.height, buffer.stride,
        layout.next_button, "NEXT"
    );
    draw_button(
        pixels, buffer.width, buffer.height, buffer.stride,
        layout.drop_button, "DROP"
    );

    ANativeWindow_unlockAndPost(state->app->window);
    state->redraw = false;
}

static bool active_piece_hit(
    const struct game_state *state,
    const struct layout *layout,
    float x,
    float y
) {
    if (!state->have_active_piece) {
        return false;
    }

    int cells[CELLS_PER_PIECE][2];
    piece_cells(&state->active, cells);

    for (int index = 0; index < CELLS_PER_PIECE; ++index) {
        struct rect cell = {
            layout->board_left + cells[index][0] * layout->cell,
            layout->board_top + cells[index][1] * layout->cell,
            layout->board_left + (cells[index][0] + 1) * layout->cell,
            layout->board_top + (cells[index][1] + 1) * layout->cell
        };

        if (point_in_rect(x, y, cell)) {
            return true;
        }
    }

    return false;
}

static enum touch_target hit_target(
    const struct game_state *state,
    const struct layout *layout,
    float x,
    float y
) {
    if (point_in_rect(x, y, layout->previous_button)) {
        return TARGET_PREVIOUS;
    }
    if (point_in_rect(x, y, layout->next_button)) {
        return TARGET_NEXT;
    }
    if (point_in_rect(x, y, layout->drop_button)) {
        return TARGET_DROP;
    }
    if (active_piece_hit(state, layout, x, y)) {
        return TARGET_PIECE;
    }
    return TARGET_NONE;
}

static void change_term(struct game_state *state, int delta) {
    if (!state->have_active_piece) {
        return;
    }

    int next = state->active.term_index + delta;
    next = maximum_int(0, minimum_int(MAX_TERM_INDEX, next));

    if (next != state->active.term_index) {
        state->active.term_index = next;
        state->redraw = true;
        LOGI(
            "term selection: m=%d k=%d degree=%d coefficient=%d",
            state->active.factor,
            state->active.term_index,
            term_degree(&state->active),
            term_coefficient(&state->active)
        );
    }
}

static int32_t handle_input(
    struct android_app *app,
    AInputEvent *event
) {
    struct game_state *state = (struct game_state *)app->userData;

    if (AInputEvent_getType(event) != AINPUT_EVENT_TYPE_MOTION ||
        state->surface_width <= 0 ||
        state->surface_height <= 0) {
        return 0;
    }

    int32_t action =
        AMotionEvent_getAction(event) & AMOTION_EVENT_ACTION_MASK;
    float x = AMotionEvent_getX(event, 0);
    float y = AMotionEvent_getY(event, 0);
    int64_t event_time = (int64_t)AMotionEvent_getEventTime(event);
    struct layout layout =
        make_layout(state->surface_width, state->surface_height);

    if (action == AMOTION_EVENT_ACTION_DOWN) {
        state->touch_target = hit_target(state, &layout, x, y);
        state->touch_moved = false;
        state->down_x = x;
        state->down_y = y;
        state->last_x = x;
        state->last_y = y;
        state->down_time_millis = event_time;

        if (state->touch_target == TARGET_PIECE) {
            int grid_x = (int)(x - layout.board_left) / layout.cell;
            int grid_y = (int)(y - layout.board_top) / layout.cell;
            state->grab_offset_x = grid_x - state->active.grid_x;
            state->grab_offset_y = grid_y - state->active.grid_y;
        }

        return state->touch_target == TARGET_NONE ? 0 : 1;
    }

    if (action == AMOTION_EVENT_ACTION_MOVE &&
        state->touch_target == TARGET_PIECE) {
        float delta_x = x - state->down_x;
        float delta_y = y - state->down_y;

        if (absolute_int((int)delta_x) + absolute_int((int)delta_y) >
            maximum_int(4, layout.cell / 5)) {
            state->touch_moved = true;
        }

        int grid_x = (int)(x - layout.board_left) / layout.cell;
        int grid_y = (int)(y - layout.board_top) / layout.cell;
        int target_x = grid_x - state->grab_offset_x;
        int target_y = grid_y - state->grab_offset_y;

        move_toward(state, target_x, target_y);
        state->last_x = x;
        state->last_y = y;
        return 1;
    }

    if (action == AMOTION_EVENT_ACTION_UP) {
        enum touch_target released_over =
            hit_target(state, &layout, x, y);

        if (state->touch_target == TARGET_PIECE) {
            int64_t elapsed = event_time - state->down_time_millis;
            float total_down = y - state->down_y;

            if (state->touch_moved &&
                total_down > (float)(layout.cell * 2) &&
                elapsed >= 0 &&
                elapsed < 320) {
                hard_drop(state);
            } else if (!state->touch_moved) {
                rotate_active_piece(state);
            }
        } else if (released_over == state->touch_target) {
            if (state->touch_target == TARGET_PREVIOUS) {
                change_term(state, -1);
            } else if (state->touch_target == TARGET_NEXT) {
                change_term(state, 1);
            } else if (state->touch_target == TARGET_DROP) {
                hard_drop(state);
            }
        }

        state->touch_target = TARGET_NONE;
        state->touch_moved = false;
        return 1;
    }

    if (action == AMOTION_EVENT_ACTION_CANCEL) {
        state->touch_target = TARGET_NONE;
        state->touch_moved = false;
        return 1;
    }

    return 0;
}

static void handle_command(struct android_app *app, int32_t command) {
    struct game_state *state = (struct game_state *)app->userData;

    switch (command) {
        case APP_CMD_INIT_WINDOW:
            if (app->window != NULL) {
                ANativeWindow_setBuffersGeometry(
                    app->window,
                    0,
                    0,
                    WINDOW_FORMAT_RGBA_8888
                );
                state->window_ready = true;
                state->surface_width = ANativeWindow_getWidth(app->window);
                state->surface_height = ANativeWindow_getHeight(app->window);
                state->last_gravity_millis = now_millis();

                if (!state->have_active_piece) {
                    spawn_piece(state);
                }
                state->redraw = true;
                LOGI(
                    "window ready: %dx%d",
                    state->surface_width,
                    state->surface_height
                );
            }
            break;

        case APP_CMD_TERM_WINDOW:
            state->window_ready = false;
            state->surface_width = 0;
            state->surface_height = 0;
            break;

        case APP_CMD_GAINED_FOCUS:
            state->has_focus = true;
            state->last_gravity_millis = now_millis();
            state->redraw = true;
            break;

        case APP_CMD_LOST_FOCUS:
            state->has_focus = false;
            break;

        case APP_CMD_WINDOW_RESIZED:
        case APP_CMD_CONFIG_CHANGED:
            if (app->window != NULL) {
                state->surface_width = ANativeWindow_getWidth(app->window);
                state->surface_height = ANativeWindow_getHeight(app->window);
                state->redraw = true;
            }
            break;

        default:
            break;
    }
}

void android_main(struct android_app *app) {
    app_dummy();

    struct game_state state;
    memset(&state, 0, sizeof(state));
    state.app = app;
    state.current_path_coefficient = 1;
    state.last_gravity_millis = now_millis();

    app->userData = &state;
    app->onAppCmd = handle_command;
    app->onInputEvent = handle_input;

    LOGI("native entry: first C framebuffer Tetris slice");

    for (;;) {
        int timeout = -1;

        if (state.window_ready && state.has_focus) {
            int64_t elapsed = now_millis() - state.last_gravity_millis;
            int64_t remaining = GRAVITY_MILLIS - elapsed;
            timeout = remaining <= 0 ? 0 : (int)remaining;
        }

        int events = 0;
        struct android_poll_source *source = NULL;
        int ident = ALooper_pollOnce(
            timeout,
            NULL,
            &events,
            (void **)&source
        );
        (void)ident;

        if (source != NULL) {
            source->process(app, source);
        }

        if (app->destroyRequested != 0) {
            return;
        }

        int64_t now = now_millis();
        if (state.window_ready &&
            state.has_focus &&
            now - state.last_gravity_millis >= GRAVITY_MILLIS) {
            gravity_step(&state);
            state.last_gravity_millis = now;
        }

        if (state.window_ready && state.redraw) {
            draw_frame(&state);
        }
    }
}
