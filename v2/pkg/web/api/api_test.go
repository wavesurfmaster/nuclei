package api

import (
	"fmt"
	"io/ioutil"
	"net/http"
	"os"
	"testing"

	"github.com/projectdiscovery/nuclei/v2/pkg/protocols/common/protocolinit"
	"github.com/projectdiscovery/nuclei/v2/pkg/testutils"
	"github.com/projectdiscovery/nuclei/v2/pkg/web/api/handlers"
	"github.com/projectdiscovery/nuclei/v2/pkg/web/api/services/scans"
	"github.com/projectdiscovery/nuclei/v2/pkg/web/api/services/settings"
	"github.com/projectdiscovery/nuclei/v2/pkg/web/api/services/targets"
	"github.com/projectdiscovery/nuclei/v2/pkg/web/db"
	"github.com/stretchr/testify/require"
)

func TestAPI(t *testing.T) {
	protocolinit.Init(testutils.DefaultOptions)

	database, err := db.New("postgres://postgres:mysecretpassword@localhost:5432/postgres")
	require.Nil(t, err, "could not connect to db")
	defer database.Close()

	err = settings.InitializeDefaultSettings(database)
	require.Nil(t, err, "could not init settings to db")

	tempdir, err := ioutil.TempDir("", "test")
	require.Nil(t, err, "could not create tempdir")
	defer os.RemoveAll(tempdir)

	targets := targets.NewTargetsStorage(tempdir)
	scans := scans.NewScanService(1, database, targets)
	defer scans.Close()

	server := handlers.New(database, targets, scans)

	api := New(&Config{
		Userame:  "user",
		Password: "pass",
		Host:     "localhost",
		Port:     8082,
		TLS:      false,
		Server:   server,
	})
	http.ListenAndServe(fmt.Sprintf("%s:%d", "localhost", 8082), api.echo)
}