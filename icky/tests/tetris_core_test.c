#include "tetris_core.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define CHECK(condition) do { \
    if (!(condition)) { \
        fprintf(stderr, "FAIL line %d: %s\n", __LINE__, #condition); \
        return 1; \
    } \
} while (0)

/* Adding gravity, rotation, cells, collisions or line state requires changing
 * this contract. All five fields describe one whole-panel gesture/prefix. */
_Static_assert(sizeof(struct mock_theta_game) == 5 * sizeof(int),
               "whole-panel state contract changed");

static int expect_row(const int *actual, const int *expected, int count) {
    for (int index = 0; index < count; ++index) {
        if (actual[index] != expected[index]) {
            return 0;
        }
    }
    return 1;
}

static int arithmetic(void) {
    const int final[10] = {15, -5, -5, -4, -4, -3, 2, 2, 1, 1};
    int expected_prefix[10] = {0};
    int actual[10];
    for (int factor = 1; factor <= 5; ++factor) {
        int degrees[18], signs[18], origins[18], branches[18];
        int coefficients[10];
        int seed[10] = {0};
        int expected[10] = {0};
        /* Independent polynomial oracle:
         * B_n = n - sum_{j=1}^{n-1} q^j; A_n = B_n - q^n B_n.
         * It does not reuse the signed-cell constructor or an arbitrary row. */
        seed[0] = factor;
        for (int degree = 1; degree < factor; ++degree) {
            seed[degree] = -1;
        }
        for (int degree = 0; degree < 10; ++degree) {
            expected[degree] = seed[degree] -
                (degree >= factor ? seed[degree - factor] : 0);
        }
        CHECK(mock_theta_shape_cell_count(factor) == 4 * factor - 2);
        int count = mock_theta_shape_cells(factor, 18,
            degrees, signs, origins, branches);
        CHECK(count == 4 * factor - 2);
        for (int cell = 0; cell < count; cell += 2) {
            CHECK(branches[cell] == 0 && branches[cell + 1] == 1);
            CHECK(degrees[cell + 1] == degrees[cell] + factor);
            CHECK(signs[cell + 1] == -signs[cell]);
            CHECK(origins[cell + 1] == origins[cell]);
            CHECK(signs[cell] == 1 || signs[cell] == -1);
            CHECK(degrees[cell] >= 0 && degrees[cell] < factor);
            CHECK(origins[cell] >= 0 && origins[cell] < factor);
            if (cell == 0) {
                CHECK(degrees[cell] == 0 && signs[cell] == 1 && origins[cell] == 0);
            } else {
                int previous = (cell + 2) / 4;
                CHECK(origins[cell] == previous);
                CHECK(degrees[cell] == (cell % 4 == 2 ? 0 : previous));
                CHECK(signs[cell] == (cell % 4 == 2 ? 1 : -1));
            }
        }
        mock_theta_sum_coefficients(1, &factor, 10, coefficients);
        CHECK(expect_row(coefficients, expected, 10));
        CHECK(mock_theta_shape_cells(factor, count - 1,
            degrees, signs, origins, branches) == -count);
        CHECK(mock_theta_shape_cells(factor, count, 0, signs, origins, branches) == -count);
    }
    for (int added = 0; added <= 5; ++added) {
        CHECK(mock_theta_blog_factor(added) == (added < 5 ? 5 - added : 0));
        mock_theta_blog_coefficients(added, actual, 10);
        CHECK(expect_row(actual, expected_prefix, 10));
        if (added < 5) {
            int factor = 5 - added;
            expected_prefix[0] += factor;
            for (int degree = 1; degree < factor; ++degree) {
                expected_prefix[degree] -= 1;
            }
            expected_prefix[factor] -= factor;
            for (int degree = factor + 1; degree < 2 * factor; ++degree) {
                expected_prefix[degree] += 1;
            }
        }
    }
    CHECK(expect_row(actual, final, 10));
    CHECK(mock_theta_blog_factor(-1) == 0);
    CHECK(mock_theta_blog_factor(6) == 0);
    mock_theta_blog_coefficients(99, actual, 10);
    CHECK(expect_row(actual, final, 10));
    mock_theta_blog_coefficients(-1, actual, 10);
    for (int degree = 0; degree < 10; ++degree) {
        CHECK(actual[degree] == 0);
    }
    CHECK(mock_theta_shape_cell_count(0) == 0);
    CHECK(mock_theta_shape_cell_count(6) == 0);
    puts("PASS formula, provenance, order, every prefix, exact final row");
    return 0;
}

static int gestures(int width, int height) {
    struct mock_theta_game game, initial;
    struct mock_theta_layout layout;
    CHECK(mock_theta_layout(width, height, &layout));
    mock_theta_reset(&game);
    initial = game;
    int x = layout.board_left + layout.cell / 2;
    int source_y = layout.source_top + layout.cell / 2;
    int target_y = (layout.target_top + layout.target_bottom) / 2;
    CHECK(layout.board_left >= 0 && layout.board_left + 10 * layout.cell <= width);
    CHECK(layout.target_top < layout.target_bottom);
    CHECK(!mock_theta_pointer(&game, width, height, MOCK_THETA_POINTER_DOWN,
                              0, 0, source_y)); /* former upper-half hit bug */
    CHECK(!mock_theta_pointer(&game, width, height, MOCK_THETA_POINTER_UP,
                              0, x, target_y));
    for (int added = 0; added < 5; ++added) {
        int before[10], after[10];
        int factor = 5 - added;
        mock_theta_blog_coefficients(game.added_count, before, 10);
        CHECK(mock_theta_pointer(&game, width, height, MOCK_THETA_POINTER_DOWN,
                                 7, x, source_y));
        CHECK(!mock_theta_pointer(&game, width, height, MOCK_THETA_POINTER_DOWN,
                                  8, x, source_y));
        CHECK(!mock_theta_pointer(&game, width, height, MOCK_THETA_POINTER_UP,
                                  8, x, target_y));
        CHECK(game.added_count == added && game.active_pointer == 7);
        CHECK(mock_theta_pointer(&game, width, height, MOCK_THETA_POINTER_MOVE,
                                 7, width - 1, height - 1));
        CHECK(game.preview_offset_y >= 0);
        CHECK(layout.source_top + game.preview_offset_y + factor * layout.cell
              <= layout.target_bottom);
        CHECK(layout.target_bottom < layout.stack_bottom - 15 * layout.cell);
        mock_theta_blog_coefficients(game.added_count, after, 10);
        CHECK(expect_row(before, after, 10)); /* motion cannot alter degrees */
        CHECK(mock_theta_pointer(&game, width, height, MOCK_THETA_POINTER_CANCEL,
                                 7, x, target_y));
        CHECK(game.added_count == added && game.preview_offset_y == 0);
        CHECK(!mock_theta_pointer(&game, width, height, MOCK_THETA_POINTER_UP,
                                  7, x, target_y));
        CHECK(mock_theta_pointer(&game, width, height, MOCK_THETA_POINTER_DOWN,
                                 7, x, source_y));
        CHECK(mock_theta_pointer(&game, width, height, MOCK_THETA_POINTER_UP,
                                 7, 0, target_y)); /* wrong column area */
        CHECK(game.added_count == added);
        CHECK(mock_theta_pointer(&game, width, height, MOCK_THETA_POINTER_DOWN,
                                 7, x, source_y));
        CHECK(mock_theta_pointer(&game, width, height, MOCK_THETA_POINTER_UP,
                                 7, x, source_y)); /* tap does not add */
        CHECK(game.added_count == added);
        CHECK(mock_theta_pointer(&game, width, height, MOCK_THETA_POINTER_DOWN,
                                 7, x, source_y));
        CHECK(mock_theta_pointer(&game, width, height, MOCK_THETA_POINTER_MOVE,
                                 7, x, target_y));
        CHECK(mock_theta_pointer(&game, width, height, MOCK_THETA_POINTER_UP,
                                 7, x, target_y));
        CHECK(game.added_count == added + 1);
        CHECK(!mock_theta_pointer(&game, width, height, MOCK_THETA_POINTER_UP,
                                  7, x, target_y)); /* repeated release */
        CHECK(game.added_count == added + 1); /* including fifth release */
    }
    CHECK(!mock_theta_pointer(&game, width, height, MOCK_THETA_POINTER_DOWN,
                              7, x, source_y));
    CHECK(game.added_count == 5);
    CHECK(mock_theta_pointer(&game, width, height, MOCK_THETA_POINTER_DOWN,
                             7, width - 1, height - 1));
    CHECK(mock_theta_pointer(&game, width, height, MOCK_THETA_POINTER_UP,
                             7, x, source_y)); /* reset gesture abandoned */
    CHECK(game.added_count == 5);
    CHECK(mock_theta_pointer(&game, width, height, MOCK_THETA_POINTER_DOWN,
                             7, width - 1, height - 1));
    CHECK(mock_theta_pointer(&game, width, height, MOCK_THETA_POINTER_UP,
                             7, width - 1, height - 1));
    CHECK(memcmp(&game, &initial, sizeof(game)) == 0);
    /* Reset during an unfinished drag also restores the exact initial state. */
    CHECK(mock_theta_pointer(&game, width, height, MOCK_THETA_POINTER_DOWN,
                             7, x, source_y));
    mock_theta_reset(&game);
    CHECK(memcmp(&game, &initial, sizeof(game)) == 0);
    printf("PASS whole-panel gestures/reset at %dx%d\n", width, height);
    return 0;
}

static int render_fixture(int width, int height, int added, int offset,
                          const char *output) {
    int stride = width + 7;
    size_t count = (size_t)stride * (size_t)height;
    unsigned int *storage = malloc((count + 2) * sizeof(unsigned int));
    CHECK(storage != NULL);
    for (size_t index = 0; index < count + 2; ++index) {
        storage[index] = 0x12345678u;
    }
    unsigned int *pixels = storage + 1;
    mock_theta_render_rgba(pixels, width, height, stride, added, offset);
    CHECK(storage[0] == 0x12345678u && storage[count + 1] == 0x12345678u);
    for (int y = 0; y < height; ++y) {
        for (int x = width; x < stride; ++x) {
            CHECK(pixels[y * stride + x] == 0x12345678u);
        }
    }
    if (output != NULL) {
        FILE *file = fopen(output, "wb");
        CHECK(file != NULL);
        CHECK(fprintf(file, "P6\n%d %d\n255\n", width, height) > 0);
        for (int y = 0; y < height; ++y) {
            for (int x = 0; x < width; ++x) {
                unsigned int color = pixels[y * stride + x];
                CHECK(fputc((int)(color & 255u), file) != EOF);
                CHECK(fputc((int)((color >> 8) & 255u), file) != EOF);
                CHECK(fputc((int)((color >> 16) & 255u), file) != EOF);
            }
        }
        CHECK(fclose(file) == 0);
    }
    free(storage);
    return 0;
}

int main(int argc, char **argv) {
    CHECK(arithmetic() == 0);
    /* Generic viewport fixtures; these do not establish any physical run. */
    const int viewports[][2] = {{96,160}, {320,640}, {576,1152},
                               {720,1600}, {540,960}, {800,480}};
    for (unsigned int index = 0; index < sizeof(viewports) / sizeof(viewports[0]); ++index) {
        int width = viewports[index][0], height = viewports[index][1];
        CHECK(gestures(width, height) == 0);
        for (int added = 0; added <= 5; ++added) {
            CHECK(render_fixture(width, height, added, 0, NULL) == 0);
            CHECK(render_fixture(width, height, added, height, NULL) == 0);
        }
    }
    if (argc == 6) {
        CHECK(render_fixture(atoi(argv[1]), atoi(argv[2]), atoi(argv[3]),
                             atoi(argv[4]), argv[5]) == 0);
    } else {
        CHECK(argc == 1);
    }
    puts("PASS framebuffer bounds and padded stride");
    return 0;
}
