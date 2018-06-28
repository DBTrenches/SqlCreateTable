-- select newid() -- F394243C-E5C5-442E-8DEE-3CF44A972C7A

create schema F394243C authorization dbo;
go

create table F394243C.Child (
     constraint pk_Child primary key clustered (id)
    ,id int not null
);
go
create table F394243C.Parent (
     constraint pk_Parent primary key clustered (id)
    ,id int not null
    ,a  int not null 
        constraint chk_Bound check (a>0)
    ,b  char(1)
        constraint df_Parent_b default ('b')
    ,c  uniqueidentifier not null 
        default newid()
        constraint ak_Parent unique
    ,child_id int not null
        constraint fk_Child_Parent
        foreign key 
        references F394243C.Child (id)
    ,constraint chk_Unbound check (1=1)
);
go

create unique nonclustered index idx_Foo
    on F394243C.Parent (a)
    include (b)
    where (a=1);
go
