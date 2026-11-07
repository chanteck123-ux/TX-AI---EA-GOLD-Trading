$ErrorActionPreference='Stop'
$root='C:/Users/A/Documents/Codex/quantskills-learning-repos'
$out='C:/Users/A/Documents/Codex/outputs/quantskills-learning-20261022/codex/recheck-20261106'
function HashText($s,$algo) { $h=[Security.Cryptography.HashAlgorithm]::Create($algo); try {([BitConverter]::ToString($h.ComputeHash([Text.Encoding]::UTF8.GetBytes($s)))).Replace('-','').ToLower()} finally {$h.Dispose()} }
$rows=@(); $valid=@(); $inventory=@()
foreach($repo in @('skill-quant-factor-directional-alpha','skill-quant-factor-risk-pattern-alpha')) {
 foreach($f in Get-ChildItem "$root/$repo" -Recurse -Filter factor.py | Sort-Object FullName) {
  $t=[IO.File]::ReadAllText($f.FullName).Replace("`r`n","`n")
  $m=[regex]::Match($t,'(?ms)^SPEC = (\{.*?^\})\n')
  if(!$m.Success){throw "SPEC parse failed"}
  $spec=$m.Groups[1].Value | ConvertFrom-Json
  $body=$t.Remove($m.Index,$m.Length)
  $rp=Join-Path $f.Directory.Parent.FullName 'validation_real/result.json'
  $rt=[IO.File]::ReadAllText($rp); $result=$rt|ConvertFrom-Json
  $ratio=$null; if($result.ic_mean_5d -ne 0 -and $result.ic_std_5d -ne 0){$ratio=$result.icir_5d/($result.ic_mean_5d/$result.ic_std_5d)}
  $rows+= [pscustomobject]@{repo=$repo;id=$spec.factor_id;base=$spec.base;transform=$spec.transform;window=$spec.params.window;params=$spec.params;path=$f.FullName;sha256=(Get-FileHash $f.FullName -Algorithm SHA256).Hash;lines=($t -split "`n").Count-1;spec_lines=@(6,28);body_md5=(HashText $body MD5);body_sha256=(HashText $body SHA256);result_path=$rp;result_sha256=(Get-FileHash $rp -Algorithm SHA256).Hash;result_lines=($rt -split "`n").Count;ic_mean=$result.ic_mean_5d;ic_std=$result.ic_std_5d;icir=$result.icir_5d;ratio=$ratio;ratio_delta_sqrt252over5=($ratio-[math]::Sqrt(252/5))}
 }
 foreach($v in Get-ChildItem "$root/$repo" -Recurse -Filter validate.py){$valid += [pscustomobject]@{path=$v.FullName;sha256=(Get-FileHash $v.FullName).Hash;lines=53}}
 $inventory+= @(Get-ChildItem "$root/$repo" -Recurse -Filter '*.py' | ForEach-Object {$_.FullName})
}
$stats=[ordered]@{count=$rows.Count;repos=@($rows|Group-Object repo|Select-Object Name,Count);body_md5=@($rows|Group-Object body_md5|Select-Object Name,Count);body_sha256=@($rows|Group-Object body_sha256|Select-Object Name,Count);validation_hashes=@($valid|Group-Object sha256|Select-Object Name,Count);ratio_min=($rows.ratio|Measure-Object -Minimum).Minimum;ratio_max=($rows.ratio|Measure-Object -Maximum).Maximum;max_abs_ratio_delta=($rows|ForEach-Object {[math]::Abs($_.ratio_delta_sqrt252over5)}|Measure-Object -Maximum).Maximum;bases=@($rows|Group-Object base|Select-Object Name,Count);transforms=@($rows|Group-Object transform|Select-Object Name,Count);windows=@($rows|Group-Object window|Select-Object Name,Count);python_file_count=$inventory.Count}
[ordered]@{scope='Q16 A173 A174 only';method='Read text/JSON, SHA256 and statistics only. No third-party execution/import.';normalization='UTF-8 text; CRLF to LF; remove ^SPEC = {...} and its following newline using anchored non-greedy match.';stats=$stats;factors=$rows;validators=$valid;python_inventory=$inventory}|ConvertTo-Json -Depth 12|Set-Content "$out/Q16.evidence.json" -Encoding utf8
$stats|ConvertTo-Json -Depth 8
