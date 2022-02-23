function Get-SqlQuoteNameSparse {
<#
    .SYNOPSIS
        Approximate match for ssms highlight engine. Quotes reserved & non-reserved keywords.
        Also quotes any name that matches quotename requirements.
        Approximately: any text containing a non alphanumeric character or beginning with a number UNLESS already quoted.

    .LINK
        https://docs.microsoft.com/en-us/sql/relational-databases/databases/database-identifiers

    .EXAMPLE
        @("Column1","1Column","_1Column","Foo Bar","Transaction","Test"," Blah","[ Bork") `
        | % {Get-SqlQuoteNameSparse $_}
 #>
    [cmdletbinding()]Param(
        [parameter(
            Position=0,
            Mandatory,
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true)]
            [Alias('word')]
            [AllowEmptyString()]
            [string]$text
    )

    if(-not [string]::IsNullOrEmpty($text)){
        $colorWords = (Get-SqlKeyWords).word;
        $needsQuote = $false

        if($colorWords -Contains $text){$needsQuote=$true}
        if($text -match "[^a-zA-Z0-9#_]"){$needsQuote=$true}
        if($text[0] -match "[0-9]"){$needsQuote=$true}

        if($text.StartsWith("[") -and $text.EndsWith("]")){$needsQuote=$false}

        if($needsQuote){$text="[$text]"}
    }else{
        $text = ""
    }

    [pscustomobject]@{
        Text = $text
    }
}
