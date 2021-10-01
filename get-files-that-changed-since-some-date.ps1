$filter_date = '01/10/2021'
dir | where-object {$_.LastWriteTime -gt $filter_date}
