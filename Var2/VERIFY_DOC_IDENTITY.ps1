$pairs = @(
    @{
        Source = "Exemple prelucrari de semnal\Exemple prelucrari de semnal\Visual DSP\test_AGC\agc.asm"
        Target = "Var2\VisualDSP\test_AGC\agc.asm"
    }
    @{
        Source = "Exemple prelucrari de semnal\Exemple prelucrari de semnal\Visual DSP\test_AGC\agc.dpj"
        Target = "Var2\VisualDSP\test_AGC\agc.dpj"
    }
    @{
        Source = "Exemple prelucrari de semnal\Exemple prelucrari de semnal\Visual DSP\test_AGC\agc.mak"
        Target = "Var2\VisualDSP\test_AGC\agc.mak"
    }
    @{
        Source = "Exemple prelucrari de semnal\Exemple prelucrari de semnal\Visual DSP\test_AGC\ADSP-2181.ldf"
        Target = "Var2\VisualDSP\test_AGC\ADSP-2181.ldf"
    }
    @{
        Source = "Exemple prelucrari de semnal\Exemple prelucrari de semnal\Visual DSP\test_AGC\def2181.h"
        Target = "Var2\VisualDSP\test_AGC\def2181.h"
    }
    @{
        Source = "Exemple prelucrari de semnal\Exemple prelucrari de semnal\Visual DSP\test_ALE\ALE.H"
        Target = "Var2\VisualDSP\test_ALE\ALE.H"
    }
    @{
        Source = "Exemple prelucrari de semnal\Exemple prelucrari de semnal\Visual DSP\test_ALE\ALE_FCT.DSP"
        Target = "Var2\VisualDSP\test_ALE\ALE_FCT.DSP"
    }
    @{
        Source = "Exemple prelucrari de semnal\Exemple prelucrari de semnal\Visual DSP\test_ALE\ALE_IO.DSP"
        Target = "Var2\VisualDSP\test_ALE\ALE_IO.DSP"
    }
    @{
        Source = "Exemple prelucrari de semnal\Exemple prelucrari de semnal\Visual DSP\test_ALE\ALE_TEST.DSP"
        Target = "Var2\VisualDSP\test_ALE\ALE_TEST.DSP"
    }
    @{
        Source = "Exemple prelucrari de semnal\Exemple prelucrari de semnal\Visual DSP\test_ALE\ale.dpj"
        Target = "Var2\VisualDSP\test_ALE\ale.dpj"
    }
    @{
        Source = "Exemple prelucrari de semnal\Exemple prelucrari de semnal\Visual DSP\test_ALE\ale.mak"
        Target = "Var2\VisualDSP\test_ALE\ale.mak"
    }
    @{
        Source = "Exemple prelucrari de semnal\Exemple prelucrari de semnal\Visual DSP\test_ALE\ADSP-2181_ASM.ldf"
        Target = "Var2\VisualDSP\test_ALE\ADSP-2181_ASM.ldf"
    }
    @{
        Source = "Exemple prelucrari de semnal\Exemple prelucrari de semnal\Visual DSP\test_MF\median.asm"
        Target = "Var2\VisualDSP\test_MF\median.asm"
    }
    @{
        Source = "Exemple prelucrari de semnal\Exemple prelucrari de semnal\Visual DSP\test_MF\median_filter.dpj"
        Target = "Var2\VisualDSP\test_MF\median_filter.dpj"
    }
    @{
        Source = "Exemple prelucrari de semnal\Exemple prelucrari de semnal\Visual DSP\test_MF\median_filter.mak"
        Target = "Var2\VisualDSP\test_MF\median_filter.mak"
    }
    @{
        Source = "Exemple prelucrari de semnal\Exemple prelucrari de semnal\Visual DSP\test_MF\ADSP-2181.ldf"
        Target = "Var2\VisualDSP\test_MF\ADSP-2181.ldf"
    }
    @{
        Source = "Exemple prelucrari de semnal\Exemple prelucrari de semnal\Visual DSP\test_MF\def2181.h"
        Target = "Var2\VisualDSP\test_MF\def2181.h"
    }
    @{
        Source = "DSP test\DSP test\test_ext\def2181.h"
        Target = "Var2\ADSP\def2181.h"
    }
    @{
        Source = "Exemple prelucrari de semnal\Exemple prelucrari de semnal\Visual DSP\test_AGC\Debug\input_agc.dat"
        Target = "Var2\test_inputs\input_agc.dat"
    }
    @{
        Source = "Exemple prelucrari de semnal\Exemple prelucrari de semnal\Visual DSP\test_ALE\Debug\input_ALE.dat"
        Target = "Var2\test_inputs\input_ALE.dat"
    }
    @{
        Source = "Exemple prelucrari de semnal\Exemple prelucrari de semnal\Visual DSP\test_MF\Debug\input_imp.dat"
        Target = "Var2\test_inputs\input_imp.dat"
    }
)

$reportLines = @()
$reportLines += "# Doc Match Report"
$reportLines += ""
$reportLines += "Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
$reportLines += ""
$reportLines += "| Status | Source | Target | SHA256 |"
$reportLines += "| --- | --- | --- | --- |"

$allOk = $true

foreach ($pair in $pairs) {
    $sourceHash = (Get-FileHash -Algorithm SHA256 $pair.Source).Hash
    $targetHash = (Get-FileHash -Algorithm SHA256 $pair.Target).Hash
    $status = if ($sourceHash -eq $targetHash) { "MATCH" } else { "DIFF" }

    if ($status -ne "MATCH") {
        $allOk = $false
    }

    $reportLines += "| $status | $($pair.Source) | $($pair.Target) | $targetHash |"
}

$reportPath = "Var2\DOC_MATCH_REPORT.md"
$reportLines | Set-Content -Encoding UTF8 $reportPath

if ($allOk) {
    Write-Host "All copied files match their documented source files."
    Write-Host "Report written to $reportPath"
    exit 0
}

Write-Error "At least one copied file does not match its documented source file."
Write-Host "Report written to $reportPath"
exit 1
