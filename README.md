# DDS_vhdl
This is the file to generate a DDS using VHDL.

This module has two options:

    - Generate a continuous signal every clock cycle that the enable port is active. (*CONT*)
    - Generate the specific phase of the signal that the user sets in the phase port. (*PHASE*)

Waves generated:
- Sin
- Cos

## Instance

``` vhdl
DDS_trig_inst : entity work.DDS_trig
  generic map (
    G_N_SAMPLES => G_N_SAMPLES,
    G_INIT_PHASE => G_INIT_PHASE,
    G_WIDTH => G_WIDTH,
    G_TYPE => G_TYPE    -- CONT / PHASE
  )
  port map (
    CLK_I => CLK_I,
    RST_N_I => RST_N_I,
    EN_I => EN_I,
    PHASE_I => PHASE_I,
    SINE_O => SINE_O,
    COSINE_O => COSINE_O
  );

```

### Images

![if](./img/if.png)

![img](./img/img.png)