CREATE TABLE IF NOT EXISTS "public".templates ( 
	id                   bigserial NOT NULL,
	name                 varchar(100) NOT NULL,
	folder               varchar NOT NULL,
	"path"               varchar  NOT NULL,
	contents             text  NOT NULL,
	createdat            timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
	updatedat            date  NOT NULL DEFAULT CURRENT_DATE,
    hash                 varchar  NOT NULL,
	CONSTRAINT pk_templates_id PRIMARY KEY ( id ),
	CONSTRAINT idx_unique_paths UNIQUE ( "path" ) 
);

CREATE TABLE IF NOT EXISTS "public".versions ( 
	id                   int NOT NULL,
	templates            varchar NOT NULL,
	CONSTRAINT idx_unique_id UNIQUE ( "id" ) 
);

CREATE TABLE IF NOT EXISTS "public".targets ( 
	id                   bigserial NOT NULL ,
	name                 varchar(100) NOT NULL,
    internalid           varchar NOT NULL,
    filename             varchar NOT NULL,
    total                bigint NOT NULL,
	createdat            timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP  ,
	updatedat            timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP  ,
	CONSTRAINT pk_targets_id PRIMARY KEY ( id )
 );


CREATE TABLE IF NOT EXISTS "public".settings ( 
	settingdata          varchar NOT NULL,
	datatype             varchar NOT NULL,
	name                 varchar(100) NOT NULL,
	CONSTRAINT unq_settings UNIQUE ( name ) 
 );


CREATE TABLE IF NOT EXISTS "public".scans ( 
	name                 varchar(100) NOT NULL,
	status               varchar(30) NOT NULL,
	scantime             bigint NOT NULL,
	hosts                bigint NOT NULL,
	scansource           varchar NOT NULL,
	templates            varchar[] NOT NULL,
	targets              varchar[] NOT NULL,
	config				 varchar,
	runnow 				 boolean,
	reporting 			 varchar,
	scheduleoccurence 	 varchar,
	scheduletime 		 varchar,
	id                   bigserial NOT NULL,
	CONSTRAINT pk_scans_id PRIMARY KEY ( id )
);

CREATE TABLE IF NOT EXISTS "public".issues ( 
	template			 varchar NOT NULL,
	templateurl          varchar,
	templateid           varchar,
	templatepath         varchar,
	templatename         varchar NOT NULL,
	author      		 varchar,
	labels               varchar[],
	description          varchar NOT NULL,
	reference            varchar[],
	severity             varchar NOT NULL,
	templatemetadata     varchar,
	cvss                 float8,
	cwe                  integer[],
	cveid                varchar,
	cvssmetrics          varchar,
	remediation          varchar,
	matchername			 varchar,
	extractorname        varchar,
    resulttype           varchar NOT NULL,
	host				 varchar NOT NULL,
	path				 varchar,
	matchedat            varchar NOT NULL,
	extractedresults     varchar[],
	request              varchar,
	response             varchar,
	metadata             varchar,
	ip                   varchar,
	interaction          varchar,
	curlcommand          varchar,
	matcherstatus        boolean,
	title                varchar NOT NULL,
	createdat            timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP  ,
	updatedat            timestamptz  NOT NULL DEFAULT CURRENT_TIMESTAMP  ,
	scansource           varchar NOT NULL,
	issuestate           varchar NOT NULL,
	hash				 varchar NOT NULL,
	id                   bigserial NOT NULL,
	scanid               bigint NOT NULL,
	CONSTRAINT pk_issues_id PRIMARY KEY ( id ),
	CONSTRAINT unq_hash UNIQUE ( hash ) 
);

-- name: InsertOrUpdateVersion :exec
INSERT INTO "public".versions 
(id, templates) VALUES
(1, $1) ON CONFLICT (id) DO UPDATE set templates=$1;

-- name: GetVersion :one
SELECT templates FROM "public".versions WHERE id=1 LIMIT 1;

-- name: GetTemplates :many
SELECT id, name, folder, "path", createdat, updatedat, hash
FROM
	"public".templates
ORDER BY id
LIMIT @sql_limit offset @sql_offset;

-- name: GetTemplatesByFolder :many
SELECT id, name, "path", createdat, updatedat, hash
FROM
	"public".templates WHERE folder=$1;

-- name: GetTemplatesByFolderOne :one
SELECT id, name, "path", createdat, updatedat, hash
FROM
	"public".templates WHERE folder=$1 LIMIT 1;

-- name: GetTemplatesBySearchKey :many
SELECT id, name, folder, "path", createdat, updatedat, hash
FROM
	"public".templates WHERE path LIKE '%'||$1||'%'
ORDER BY id
LIMIT @sql_limit offset @sql_offset;

-- name: DeleteTemplate :exec
DELETE FROM public.templates WHERE path=$1;

-- name: GetTemplateContents :one
SELECT contents FROM public.templates WHERE path=$1 LIMIT 1;

-- name: GetTemplatesForScan :many
SELECT path, contents FROM public.templates WHERE folder=$1 OR path=$1 OR path LIKE $1||'%';

-- name: AddTemplate :one
INSERT INTO public.templates
( name, folder, "path", contents, createdat, updatedat, hash) VALUES ($1, $2, $3 , $4, NOW(), NOW(), $5) RETURNING id;

-- name: UpdateTemplate :exec
UPDATE public.templates SET contents=$1, updatedat=$2, hash=$4 WHERE path=$3;

-- name: DeleteTarget :exec
DELETE FROM public.targets WHERE ID=$1;

-- name: AddTarget :one
INSERT INTO public.targets
	( name, createdat, updatedat, internalid, filename, total) VALUES ($1, NOW(), NOW(), $2, $3, $4) RETURNING id;

-- name: GetTarget :one
SELECT name, internalid, filename, total, createdat, updatedat
FROM
	public.targets WHERE ID=$1 LIMIT 1;

-- name: GetTargetByName :one
SELECT id, internalid, filename, total, createdat, updatedat
FROM
	public.targets WHERE name=$1 LIMIT 1;

-- name: GetTargets :many
SELECT id, name, createdat, updatedat, internalid, filename, total
FROM
	public.targets
ORDER BY id
LIMIT @sql_limit offset @sql_offset;

-- name: GetTargetsForSearch :many
SELECT id, name, createdat, updatedat, internalid, filename, total
FROM
	"public".targets WHERE name LIKE '%'||$1||'%' OR filename LIKE '%'||$1||'%'
ORDER BY id
LIMIT @sql_limit offset @sql_offset;

-- name: UpdateTargetMetadata :exec
UPDATE targets SET total=total+$1 AND updatedAt=NOW() WHERE id=$2;

-- name: AddScan :one
INSERT INTO "public".scans
	( name, status, scantime, hosts, scansource, templates, targets, config, runnow, reporting, scheduleoccurence, scheduletime) VALUES ( $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12 ) RETURNING id;

-- name: DeleteScan :exec
DELETE FROM "public".scans WHERE id=$1;

-- name: GetScan :one
SELECT name, status, scantime, hosts, scansource, templates, targets, config, runnow, reporting, scheduleoccurence, 
	scheduletime, id
FROM
	"public".scans WHERE id=$1 LIMIT 1;

-- name: GetScans :many
SELECT name, status, scantime, hosts, scansource, templates, targets, config, runnow, reporting, scheduleoccurence, 
	scheduletime, id
FROM
	"public".scans
ORDER BY id
LIMIT @sql_limit offset @sql_offset;

-- name: GetScansForSchedule :many
SELECT name, status, scantime, hosts, scansource, templates, targets, config, runnow, reporting, 
	scheduletime, id
FROM
	"public".scans WHERE scheduleoccurence=$1;

-- name: GetScansBySearchKey :many
SELECT name, status, scantime, hosts, scansource, templates, targets, config, runnow, reporting, scheduleoccurence, 
	scheduletime, id
FROM
	"public".scans WHERE name LIKE '%'||$1||'%';

-- name: UpdateScanState :exec
UPDATE "public".scans SET status=$2 WHERE id=$1 ;

-- name: AddIssue :one
INSERT INTO "public".issues
	(template,templateurl,templateid,templatepath,templatename,author,labels,description,reference,severity,templatemetadata,cvss,cwe,cveid,cvssmetrics,remediation,matchername,extractorname,resulttype,host,path,matchedat,extractedresults,request,response,metadata,ip,interaction,curlcommand,matcherstatus,title,createdat,updatedat,scansource,issuestate,hash,scanid) 
VALUES 
    ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20, $21, $22, $23, $24, $25, $26, $27, $28, $29, $30, $31, NOW(), NOW(), $32, $33, $34, $35) RETURNING id;

-- name: DeleteIssue :exec
DELETE FROM "public".issues WHERE id=$1;


-- name: DeleteIssueByScanID :exec
DELETE FROM "public".issues WHERE scanid=$1;

-- name: GetIssue :one
SELECT *
FROM
	"public".issues WHERE id=$1 LIMIT 1;

-- name: GetIssues :many
SELECT id, scanid, matchedat, title, severity, createdat, updatedat, scansource
FROM
	"public".issues
ORDER BY id
LIMIT @sql_limit offset @sql_offset;

-- name: GetIssuesByScanID :many
SELECT id, scanid, matchedat, title, severity, createdat, updatedat, scansource
FROM
	"public".issues WHERE scanid=$1
ORDER BY id
LIMIT @sql_limit offset @sql_offset;

-- name: GetIssuesMatches :many
SELECT id, matchedat, templatename, severity, author
FROM
	"public".issues WHERE scanid=$1
ORDER BY id
LIMIT @sql_limit offset @sql_offset;

-- name: UpdateIssue :exec
UPDATE "public".issues SET issuestate=$2 WHERE id=$1 ;

-- name: SetSettings :exec
INSERT INTO "public".settings
	( settingdata, datatype, name) VALUES ( $1, $2, $3) ON CONFLICT (name) DO UPDATE SET settingdata=$1;

-- name: GetSettings :many
SELECT settingdata, datatype, name
FROM
	"public".settings;

-- name: GetSettingByName :one
SELECT settingdata, datatype
FROM
	"public".settings WHERE name=$1 LIMIT 1;


-- name: UpdateSettings :exec
UPDATE "public".settings SET settingdata=$1 WHERE name=$2;