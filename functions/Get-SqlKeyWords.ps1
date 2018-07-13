function Get-SqlKeyWords {
<#
    .SYNOPSIS
        Lists reserved and non-reserved keywords as of SQL Server 2017 CU5.
    
    .LINK
        Full citation can be found at https://github.com/petervandivier/hello-world/blob/master/reserved_keywords.sql

    .DESCRIPTION
        Reserved and non-reserved keywords matching the following pattern from the above reference will be returned
        for the purposes of prettifying procedurally genereated SQL scripts. 
        
        select word 
        from dbo.color_words 
        where patindex('%[^a-zA-Z]%',word)=0;

    .EXAMPLE
        All words returned by this function should be color-formatted in the default SSMS editor.

        Get-SqlKeyWords | Where-Object {$_.word.StartsWith("a")} | clip
        Start-Process ssms

#>
    [string[]]$keywords=@(
        "abort", "abs", "absolute", "acos", "action", "add", "address", "admin", "after"
        "aggregate", "all", "alter", "and", "any", "application", "as", "asc", "ascii", "asin"
        "assemblyproperty", "asymkeyproperty", "asymmetric", "at", "atan", "atomic"
        "authorization", "avg", "backup", "before", "begin", "between", "bigint"
        "binary", "bit", "break", "browse", "bulk", "by", "call", "cascade", "case"
        "cast", "catalog", "ceiling", "certencoded", "certprivatekey", "char"
        "character", "charindex", "check", "checkpoint", "checksum", "choose", "close"
        "clustered", "coalesce", "collate", "collationproperty", "column"
        "columnproperty", "commit", "compress", "compute", "concat", "connect"
        "connectionproperty", "constraint", "contains", "containstable", "continue"
        "convert", "copy", "cos", "cot", "count", "create", "cross", "cube", "curdate"
        "current", "cursor", "curtime", "data", "database", "databasepropertyex"
        "datalength", "date", "dateadd", "datediff", "datefromparts", "datename"
        "datepart", "datetime", "datetimefromparts", "datetimeoffset"
        "datetimeoffsetfromparts", "day", "dayname", "dayofmonth", "dayofweek", "dbcc", "deallocate"
        "dec", "decimal", "declare", "decompress", "decryptbyasymkey"
        "decryptbycert", "decryptbykey", "decryptbykeyautoasymkey", "decryptbykeyautocert"
        "decryptbypassphrase", "default", "degrees", "delete", "deny", "desc"
        "difference", "disk", "distinct", "distributed", "double", "drop", "dump"
        "dynamic", "else", "encryptbyasymkey", "encryptbycert", "encryptbykey"
        "encryptbypassphrase", "end", "eomonth", "errlvl", "escape", "event", "eventdata", "except"
        "exec", "execute", "exists", "exit", "exp", "external", "extract", "fetch"
        "file", "filegroupproperty", "fileproperty", "fillfactor", "filter"
        "first", "float", "floor", "following", "for", "foreign", "format"
        "formatmessage", "freetext", "freetexttable", "from", "full"
        "fulltextcatalogproperty", "fulltextserviceproperty", "function", "geography", "geometry", "get"
        "getansinull", "getdate", "getutcdate", "global", "go", "goto", "grant"
        "group", "grouping", "hashbytes", "having", "hierarchyid", "holdlock", "hour"
        "identity", "identitycol", "if", "iif", "image", "immediate", "in"
        "include", "index", "indexproperty", "inner", "insensitive", "insert", "int"
        "integer", "intersect", "into", "is", "isdate", "isjson", "isnull"
        "isnumeric", "isolation", "iterate", "join", "key", "kill", "language", "last"
        "left", "len", "level", "like", "lineno", "load", "local", "log", "lower"
        "ltrim", "match", "max", "merge", "min", "minute", "mod", "modify", "money"
        "month", "monthname", "move", "national", "nchar", "newid", "newsequentialid"
        "next", "no", "nocheck", "nonclustered", "none", "normalize", "not"
        "ntext", "ntile", "null", "nullif", "numeric", "nvarchar", "object"
        "objectproperty", "objectpropertyex", "of", "off", "offsets", "on", "online", "open"
        "opendatasource", "openjson", "openquery", "openrowset", "openxml"
        "option", "or", "order", "out", "outer", "output", "over", "parameters", "parse"
        "parsename", "partial", "partition", "path", "patindex", "percent"
        "permissions", "pi", "pivot", "plan", "power", "preceding", "precision", "primary"
        "print", "prior", "proc", "procedure", "public", "publishingservername"
        "pwdcompare", "pwdencrypt", "quarter", "quotename", "radians", "raiserror"
        "rand", "range", "rank", "read", "readtext", "real", "reconfigure"
        "recursive", "references", "relative", "replace", "replicate", "replication"
        "reset", "restore", "restrict", "return", "returns", "reverse", "revert"
        "revoke", "right", "role", "rollback", "rollup", "round", "row", "rowcount"
        "rowguidcol", "rows", "rowversion", "rtrim", "rule", "save", "schema"
        "scroll", "second", "securityaudit", "select", "semantickeyphrasetable"
        "semanticsimilaritydetailstable", "semanticsimilaritytable", "sequence"
        "serverproperty", "session", "sessionproperty", "set", "sets", "setuser", "shutdown"
        "sign", "signbyasymkey", "signbycert", "sin", "smalldatetime"
        "smalldatetimefromparts", "smallint", "smallmoney", "some", "soundex", "space", "sql"
        "sqrt", "square", "start", "state", "statement", "static", "statistics"
        "stdev", "stdevp", "str", "stuff", "substring", "sum", "switchoffset"
        "symkeyproperty", "symmetric", "sysdatetime", "sysdatetimeoffset", "system"
        "sysutcdatetime", "table", "tablesample", "tan", "text", "textptr", "textsize"
        "textvalid", "then", "time", "timefromparts", "timestamp", "tinyint"
        "to", "todatetimeoffset", "top", "tran", "transaction", "trigger", "trim"
        "truncate", "tsequal", "typeproperty", "unbounded", "unicode", "union"
        "unique", "uniqueidentifier", "unpivot", "update", "updatetext", "upper", "use"
        "user", "using", "value", "values", "var", "varbinary", "varchar", "varp"
        "varying", "verbose", "verifysignedbyasmkey", "version", "view", "waitfor"
        "week", "when", "where", "while", "with", "within", "without", "writetext"
        "xml", "year", "zone"
    )

    $keywords | ForEach-Object {
        [PSCustomObject] @{
            word = $PSItem
        }
    }
}