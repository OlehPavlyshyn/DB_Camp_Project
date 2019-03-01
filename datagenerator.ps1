$j = 5
While($true)
    {
    Write-Host $i;
    Write-Host $j;
    $r = Get-Random  -Minimum 1 -Maximum 4
    Switch ($i) 
    { 2 {Invoke-RestMethod -Method GET -Uri "http://127.0.0.1:5000/AddPayINTransaction/$r";
        Invoke-RestMethod -Method GET -Uri "http://127.0.0.1:5000/AddPayOUTTransaction/$r";}
      4{Invoke-RestMethod -Method GET -Uri "http://127.0.0.1:5000/AddUsers/$r"
        } 
      6 {Invoke-RestMethod -Method GET -Uri "http://127.0.0.1:5000/AddPayINTransaction/$r";
        Invoke-RestMethod -Method GET -Uri "http://127.0.0.1:5000/AddPayOUTTransaction/$r";}
      8{Invoke-RestMethod -Method GET -Uri "http://127.0.0.1:5000/UpdateBet/$r";
        Invoke-RestMethod -Method GET -Uri "http://127.0.0.1:5000/DeleteBet/$r";
        Invoke-RestMethod -Method GET -Uri "http://127.0.0.1:5000/AddUsers/$r";
        Invoke-RestMethod -Method GET -Uri "http://127.0.0.1:5000/AddPayINTransaction/$r";
        Invoke-RestMethod -Method GET -Uri "http://127.0.0.1:5000/AddPayOUTTransaction/$r";
        Invoke-RestMethod -Method GET -Uri "http://127.0.0.1:5000/AddCreditCard/$r";
        Invoke-RestMethod -Method GET -Uri "http://127.0.0.1:5000/MatchResult";}
    };
    if ($j -eq 6) { Invoke-RestMethod -Method GET -Uri "http://127.0.0.1:5000/AddEvent/$r"; 
    $j = 0;};
    $i++;
    if ($i -eq 9) {$i = 0; $j ++;};

    Start-Sleep -s 1
    }
