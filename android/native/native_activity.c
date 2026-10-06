#include <android/input.h>
#include <android/log.h>
#include <android/native_window.h>
#include <android_native_app_glue.h>

#include <stdbool.h>
#include <string.h>

#include "tetris_core.h"

#define LOG_TAG "MockThetaIcky"
#define LOGI(...) \
    __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)

struct app_state {
    struct android_app *app;

    bool window_ready;
    bool dragging;
    bool redraw;

    int width;
    int height;

    int added_count;
    int preview_offset_y;

    float drag_start_y;
};

static int clamp_int(
    int value,
    int minimum,
    int maximum
) {
    if (value < minimum) {
        return minimum;
    }

    if (value > maximum) {
        return maximum;
    }

    return value;
}

static void draw_frame(struct app_state *state) {
    ANativeWindow_Buffer buffer;

    if (!state->window_ready ||
        state->app->window == NULL) {
        return;
    }

    if (ANativeWindow_lock(
            state->app->window,
            &buffer,
            NULL
        ) != 0) {
        return;
    }

    state->width = buffer.width;
    state->height = buffer.height;

    mock_theta_render_rgba(
        (unsigned int *)buffer.bits,
        buffer.width,
        buffer.height,
        buffer.stride,
        state->added_count,
        state->preview_offset_y
    );

    ANativeWindow_unlockAndPost(
        state->app->window
    );

    state->redraw = false;
}

static void reset_demo(struct app_state *state) {
    state->added_count = 0;
    state->preview_offset_y = 0;
    state->dragging = false;
    state->redraw = true;
}

static int32_t handle_input(
    struct android_app *app,
    AInputEvent *event
) {
    struct app_state *state =
        (struct app_state *)app->userData;

    if (AInputEvent_getType(event) !=
        AINPUT_EVENT_TYPE_MOTION) {
        return 0;
    }

    int32_t action =
        AMotionEvent_getAction(event) &
        AMOTION_EVENT_ACTION_MASK;

    float y = AMotionEvent_getY(event, 0);

    if (action == AMOTION_EVENT_ACTION_DOWN) {
        if (state->added_count >=
            MOCK_THETA_FACTOR_COUNT) {
            state->dragging = false;
            return 1;
        }

        if (state->height > 0 &&
            y < (float)state->height * 0.48f) {
            state->dragging = true;
            state->drag_start_y = y;
            state->preview_offset_y = 0;
            state->redraw = true;
            return 1;
        }

        return 0;
    }

    if (action == AMOTION_EVENT_ACTION_MOVE &&
        state->dragging) {
        int offset =
            (int)(y - state->drag_start_y);

        state->preview_offset_y =
            clamp_int(
                offset,
                0,
                state->height / 2
            );

        state->redraw = true;
        return 1;
    }

    if (action == AMOTION_EVENT_ACTION_UP) {
        if (state->added_count >=
            MOCK_THETA_FACTOR_COUNT) {
            reset_demo(state);
            return 1;
        }

        if (state->dragging) {
            int commit =
                state->height > 0 &&
                y >= (float)state->height * 0.50f;

            if (commit) {
                state->added_count += 1;
                LOGI(
                    "Tetris addition committed: %d/5",
                    state->added_count
                );
            }

            state->preview_offset_y = 0;
            state->dragging = false;
            state->redraw = true;
            return 1;
        }

        return 0;
    }

    if (action == AMOTION_EVENT_ACTION_CANCEL) {
        state->dragging = false;
        state->preview_offset_y = 0;
        state->redraw = true;
        return 1;
    }

    return 0;
}

static void handle_command(
    struct android_app *app,
    int32_t command
) {
    struct app_state *state =
        (struct app_state *)app->userData;

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
                state->width =
                    ANativeWindow_getWidth(app->window);
                state->height =
                    ANativeWindow_getHeight(app->window);
                state->redraw = true;

                LOGI(
                    "window ready: %dx%d",
                    state->width,
                    state->height
                );
            }
            break;

        case APP_CMD_TERM_WINDOW:
            state->window_ready = false;
            break;

        case APP_CMD_GAINED_FOCUS:
        case APP_CMD_WINDOW_RESIZED:
        case APP_CMD_CONFIG_CHANGED:
            state->redraw = true;
            break;

        default:
            break;
    }
}

void android_main(struct android_app *app) {
    struct app_state state;
    memset(&state, 0, sizeof(state));

    state.app = app;
    state.redraw = true;

    app->userData = &state;
    app->onAppCmd = handle_command;
    app->onInputEvent = handle_input;

    LOGI("native entry: ICK C coefficient Tetris");

    for (;;) {
        int events = 0;
        struct android_poll_source *source = NULL;

        int timeout =
            state.window_ready &&
            state.redraw
                ? 0
                : -1;

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

        if (state.window_ready &&
            state.redraw) {
            draw_frame(&state);
        }
    }
}
