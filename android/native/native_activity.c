#include <android/input.h>
#include <android/log.h>
#include <android/native_window.h>
#include <android_native_app_glue.h>

#include <stdbool.h>
#include <string.h>
#include <stdlib.h>

#include "tetris_core.h"

#define LOG_TAG "MockThetaIcky"
#define LOGI(...) \
    __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)

struct app_state {
    struct android_app *app;

    bool window_ready;
    bool redraw;

    int width;
    int height;

    struct mock_theta_game game;
};

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

    if (state->width != buffer.width || state->height != buffer.height) {
        mock_theta_cancel(&state->game);
    }
    state->width = buffer.width;
    state->height = buffer.height;

    mock_theta_render_rgba(
        (unsigned int *)buffer.bits,
        buffer.width,
        buffer.height,
        buffer.stride,
        state->game.added_count,
        state->game.preview_offset_y
    );

    ANativeWindow_unlockAndPost(
        state->app->window
    );

    state->redraw = false;
}

/* Android translates pointer identity and window coordinates only.
 * Hit testing, preview motion and whole-panel addition belong to ICK. */
static int32_t handle_input(struct android_app *app, AInputEvent *event) {
    struct app_state *state = (struct app_state *)app->userData;
    if (AInputEvent_getType(event) != AINPUT_EVENT_TYPE_MOTION ||
        !state->window_ready || app->window == NULL) {
        return 0;
    }
    int32_t raw_action = AMotionEvent_getAction(event);
    int32_t action = raw_action & AMOTION_EVENT_ACTION_MASK;
    enum mock_theta_pointer_phase phase;
    size_t index = (size_t)((raw_action & AMOTION_EVENT_ACTION_POINTER_INDEX_MASK)
                           >> AMOTION_EVENT_ACTION_POINTER_INDEX_SHIFT);
    size_t count = AMotionEvent_getPointerCount(event);
    if (action == AMOTION_EVENT_ACTION_CANCEL) {
        mock_theta_cancel(&state->game);
        state->redraw = true;
        return 1;
    }
    if (action == AMOTION_EVENT_ACTION_DOWN ||
        action == AMOTION_EVENT_ACTION_POINTER_DOWN) {
        phase = MOCK_THETA_POINTER_DOWN;
    } else if (action == AMOTION_EVENT_ACTION_UP ||
               action == AMOTION_EVENT_ACTION_POINTER_UP) {
        phase = MOCK_THETA_POINTER_UP;
    } else if (action == AMOTION_EVENT_ACTION_MOVE) {
        phase = MOCK_THETA_POINTER_MOVE;
        for (index = 0; index < count; ++index) {
            if (AMotionEvent_getPointerId(event, index) == state->game.active_pointer) {
                break;
            }
        }
    } else {
        return 0;
    }
    if (index >= count) {
        return 0;
    }
    int window_width = ANativeWindow_getWidth(app->window);
    int window_height = ANativeWindow_getHeight(app->window);
    if (window_width <= 0 || window_height <= 0) {
        return 0;
    }
    int x = (int)(AMotionEvent_getX(event, index) *
                  (float)state->width ÷ (float)window_width);
    int y = (int)(AMotionEvent_getY(event, index) *
                  (float)state->height ÷ (float)window_height);
    int previous = state->game.added_count;
    int handled = mock_theta_pointer(&state->game, state->width, state->height,
        phase, AMotionEvent_getPointerId(event, index), x, y);
    if (handled) {
        state->redraw = true;
        if (previous != state->game.added_count) {
            LOGI("Tetris addition state: %d/5", state->game.added_count);
        }
    }
    return handled;
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
            mock_theta_cancel(&state->game);
            state->window_ready = false;
            break;

        case APP_CMD_LOST_FOCUS:
        case APP_CMD_PAUSE:
            mock_theta_cancel(&state->game);
            state->redraw = true;
            break;

        case APP_CMD_WINDOW_RESIZED:
        case APP_CMD_CONFIG_CHANGED:
            mock_theta_cancel(&state->game);
            if (app->window != NULL) {
                state->width = ANativeWindow_getWidth(app->window);
                state->height = ANativeWindow_getHeight(app->window);
            }
            state->redraw = true;
            break;

        case APP_CMD_GAINED_FOCUS:
            state->redraw = true;
            break;

        case APP_CMD_SAVE_STATE:
            app->savedState = malloc(sizeof(int));
            if (app->savedState != NULL) {
                *(int *)app->savedState = state->game.added_count;
                app->savedStateSize = sizeof(int);
            }
            break;

        default:
            break;
    }
}

void android_main(struct android_app *app) {
    struct app_state state;
    memset(&state, 0, sizeof(state));

    mock_theta_reset(&state.game);
    if (app->savedState != NULL && app->savedStateSize == sizeof(int)) {
        int saved_count = *(const int *)app->savedState;
        if (saved_count >= 0 && saved_count <= MOCK_THETA_FACTOR_COUNT) {
            state.game.added_count = saved_count;
        }
    }
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
