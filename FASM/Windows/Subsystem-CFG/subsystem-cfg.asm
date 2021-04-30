;control flow guard was introduced in Windows 8.1. This means if by any purpose your program ONLY target
;Windows 8.1 (subsystem 6.1 or 10.0) and above that has control flow guard, your executable must have cfg info
;(which can be specified in the load configuration directory in the pe file (index 10 of data directories).
;this example shows the most simplest form of it. The load config directory structure size must at least
;includes up until GuardFlags, and if the values of all members are 0, GuardFlags must have value 0x800
;(to indicate that no scurity cookies used).

;original code was written by Tomasz Grysztar, author of Flat Assembler, and I just modify the 'format'
;directive and add the load configuration directory (data 10).

format PE64 NX GUI 10.0
entry start

include 'win64a.inc'

section '.data' data readable writeable

  _title db 'AVX playground',0
  _error db 'AVX instructions are not supported.',0

  x dq 3.14159265389

  vector_output:
    rept 16 i:0
    {
        db 'ymm',`i,': %f,%f,%f,%f',13,10
    }
    db 0

  buffer db 1000h dup ?

section '.text' code readable executable

  start:

        mov     eax,1
        cpuid
        and     ecx,18000000h
        cmp     ecx,18000000h
        jne     no_AVX
        xor     ecx,ecx
        xgetbv
        and     eax,110b
        cmp     eax,110b
        jne     no_AVX

        vbroadcastsd    ymm0, [x]
        vsqrtpd         ymm1, ymm0

        vsubpd          ymm2, ymm0, ymm1
        vsubpd          ymm3, ymm1, ymm2

        vaddpd          xmm4, xmm2, xmm3
        vaddpd          ymm5, ymm4, ymm0

        vperm2f128      ymm6, ymm4, ymm5, 03h
        vshufpd         ymm7, ymm6, ymm5, 10010011b

        vroundpd        ymm8, ymm7, 0011b
        vroundpd        ymm9, ymm7, 0

        sub     rsp,418h

    rept 16 i:0
    {
        vmovups [rsp+10h+i*32],ymm#i
    }

        mov     r8,[rsp+10h]
        mov     r9,[rsp+18h]
        lea     rdx,[vector_output]
        lea     rcx,[buffer]
        call    [sprintf]

        xor     ecx,ecx
        lea     rdx,[buffer]
        lea     r8,[_title]
        xor     r9d,r9d
        call    [MessageBoxA]

        xor     ecx,ecx
        call    [ExitProcess]

  no_AVX:

        sub     rsp,28h

        xor     ecx,ecx
        lea     rdx,[_error]
        lea     r8,[_title]
        mov     r9d,10h
        call    [MessageBoxA]

        mov     ecx,1
        call    [ExitProcess]

section '.idata' import data readable

  library kernel32,'KERNEL32.DLL',\
          user32,'USER32.DLL',\
          msvcrt,'MSVCRT.DLL'

  include 'api\kernel32.inc'
  include 'api\user32.inc'

  import msvcrt,\
         sprintf,'sprintf'


section '.rdata' data readable

data 10
.Size dd .datasize
.TimeDateStamp  dd 0
.MajorVersion dw 0
.MinorVersion dw 0
.GlobalFlagsClear dd 0
.GlobalFlagsSet dd 0
.CriticalSectionDefaultTimeout dd 0
.DeCommitFreeBlockThreshold dq 0
.DeCommitTotalFreeThreshold dq 0
.LockPrefixTable dq 0
.MaximumAllocationSize dq 0
.VirtualMemoryThreshold dq 0
.ProcessAffinityMask dq 0
.ProcessHeapFlags dd 0
.CSDVersion dw 0
.DependentLoadFlags dw 0
.EditList dq 0
.SecurityCookie dq 0
.SEHandlerTable dq 0
.SEHandlerCount dq 0
.GuardCFCheckFunctionPointer dq 0
.GuardCFDispatchFunctionPointer dq 0
.GuardCFFunctionTable dq 0
.GuardCFFunctionCount dq 0
.GuardFlags dd 0x00000800   ;IMAGE_GUARD_SECURITY_COOKIE_UNUSED
;dw 0, 0    ;IMAGE_LOAD_CONFIG_CODE_INTEGRITY CodeIntegrity
;dd 0, 0    ;IMAGE_LOAD_CONFIG_CODE_INTEGRITY CodeIntegrity
;.GuardAddressTakenIatEntryTable dq 0
;.GuardAddressTakenIatEntryCount dq 0
;.GuardLongJumpTargetTable dq 0
;.GuardLongJumpTargetCount dq 0
;.DynamicValueRelocTable dq 0
;.CHPEMetadataPointer dq 0
;.GuardRFFailureRoutined dq 0
;.GuardRFFailureRoutineFunctionPointer dq 0
;.DynamicValueRelocTableOffset dd 0
;.DynamicValueRelocTableSection dw 0
;.Reserved2 dw 0
;.GuardRFVerifyStackPointerFunctionPointer dq 0
;.HotPatchTableOffset dd 0
;.Reserved3 dd 0
;.EnclaveConfigurationPointer dq 0
;.VolatileMetadataPointer dq 0
;.GuardEHContinuationTable dq 0
;.GuardEHContinuationCount dq 0
;dq 0
.datasize = $-.Size
end data
