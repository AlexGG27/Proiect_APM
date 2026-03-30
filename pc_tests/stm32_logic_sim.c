#include <stdint.h>
#include <stdio.h>

typedef enum
{
    ARM_STATE_WAIT_RELEASE = 0,
    ARM_STATE_WAIT_PRESS
} ArmState_t;

typedef struct
{
    ArmState_t state;
    uint8_t last_led_value;
    uint8_t last_pcda_value;
    int transmit_count;
} ArmSimContext;

static void arm_sim_init(ArmSimContext *ctx)
{
    ctx->state = ARM_STATE_WAIT_RELEASE;
    ctx->last_led_value = 0;
    ctx->last_pcda_value = 0;
    ctx->transmit_count = 0;
}

static int arm_sim_tick(ArmSimContext *ctx, uint8_t bus_value, int prg_level)
{
    switch (ctx->state)
    {
    case ARM_STATE_WAIT_RELEASE:
        if (prg_level == 0)
        {
            ctx->state = ARM_STATE_WAIT_PRESS;
        }
        return 0;

    case ARM_STATE_WAIT_PRESS:
        if (prg_level != 0)
        {
            ctx->last_led_value = bus_value;
            ctx->last_pcda_value = bus_value;
            ctx->transmit_count++;
            ctx->state = ARM_STATE_WAIT_RELEASE;
            return 1;
        }
        return 0;
    }

    return 0;
}

static int test_idle_does_not_transmit(void)
{
    ArmSimContext ctx;

    arm_sim_init(&ctx);
    arm_sim_tick(&ctx, 0xC0, 1);
    arm_sim_tick(&ctx, 0xC0, 1);
    arm_sim_tick(&ctx, 0xC0, 1);

    return ctx.transmit_count == 0;
}

static int test_agc_left_transmit(void)
{
    ArmSimContext ctx;
    int tx = 0;

    arm_sim_init(&ctx);
    tx += arm_sim_tick(&ctx, 0xC0, 0);
    tx += arm_sim_tick(&ctx, 0xC0, 1);
    tx += arm_sim_tick(&ctx, 0xC0, 0);

    return tx == 1 && ctx.transmit_count == 1 &&
           ctx.last_led_value == 0xC0 && ctx.last_pcda_value == 0xC0;
}

static int test_mf_right_transmit(void)
{
    ArmSimContext ctx;
    int tx = 0;

    arm_sim_init(&ctx);
    tx += arm_sim_tick(&ctx, 0xCA, 0);
    tx += arm_sim_tick(&ctx, 0xCA, 1);

    return tx == 1 && ctx.transmit_count == 1 &&
           ctx.last_led_value == 0xCA && ctx.last_pcda_value == 0xCA;
}

int main(void)
{
    int ok = 1;

    if (test_idle_does_not_transmit())
    {
        puts("PASS idle_does_not_transmit");
    }
    else
    {
        puts("FAIL idle_does_not_transmit");
        ok = 0;
    }

    if (test_agc_left_transmit())
    {
        puts("PASS agc_left_transmit");
    }
    else
    {
        puts("FAIL agc_left_transmit");
        ok = 0;
    }

    if (test_mf_right_transmit())
    {
        puts("PASS mf_right_transmit");
    }
    else
    {
        puts("FAIL mf_right_transmit");
        ok = 0;
    }

    puts(ok ? "PASS" : "FAIL");
    return ok ? 0 : 1;
}
