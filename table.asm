extern _cpuid
extern _get_cpuid

_get_cpuia:
  jmp _cpuid+0x20
global _get_cpuia:function

_Llzma_delta_props_encoder:
  jmp _get_cpuid+0x7300
global _Llzma_delta_props_encoder:function
