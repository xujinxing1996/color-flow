package main

import (
	"context"
	"flag"
	"fmt"
	"log/slog"
	"net"
	"net/http"
	"os"
	"os/signal"
	"strconv"
	"sync"
	"syscall"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/julienschmidt/httprouter"
)

// version holds the application version.
const version = "1.0.0"

// config holds the configuration settings for the application.
type config struct {
	port int
	env  string
	db   struct {
		dsn          string
		maxOpenConns int
		maxIdleConns int
		maxIdleTime  string
	}
	jwt struct {
		secret string
	}
}

// application holds the dependencies for the HTTP handlers.
type application struct {
	config config
	logger *slog.Logger
	models models
	wg     sync.WaitGroup
}

// models holds all the application models.
type models struct {
	users userModel
}

type userModel struct {
	db *pgxpool.Pool
}

func main() {
	var cfg config

	flag.IntVar(&cfg.port, "port", 4000, "API server port")
	flag.StringVar(&cfg.env, "env", "development", "Environment (development|staging|production)")
	flag.StringVar(&cfg.db.dsn, "db-dsn", os.Getenv("DATABASE_URL"), "PostgreSQL DSN")
	flag.IntVar(&cfg.db.maxOpenConns, "db-max-open-conns", 25, "PostgreSQL max open connections")
	flag.IntVar(&cfg.db.maxIdleConns, "db-max-idle-conns", 25, "PostgreSQL max idle connections")
	flag.StringVar(&cfg.db.maxIdleTime, "db-max-idle-time", "15m", "PostgreSQL max idle time")
	flag.StringVar(&cfg.jwt.secret, "jwt-secret", os.Getenv("JWT_SECRET"), "JWT secret key")
	flag.Parse()

	// Initialize logger
	logger := slog.New(slog.NewJSONHandler(os.Stdout, &slog.HandlerOptions{
		Level: slog.LevelInfo,
	}))

	logger.Info("starting application", "version", version, "env", cfg.env, "port", cfg.port)

	// Connect to database
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	db, err := openDB(ctx, cfg)
	if err != nil {
		logger.Error("failed to connect to database", "error", err)
		os.Exit(1)
	}
	defer db.Close()

	logger.Info("database connection pool established")

	// Initialize application
	app := &application{
		config: cfg,
		logger: logger,
		models: models{
			users: userModel{db: db},
		},
	}

	// Create server
	mux := httprouter.New()
	mux.HandlerFunc("GET", "/v1/healthcheck", app.healthcheckHandler)

	// Configure server
	srv := &http.Server{
		Addr:         net.JoinHostPort("", strconv.Itoa(cfg.port)),
		Handler:      mux,
		ErrorLog:     slog.NewLogLogger(logger.Handler(), slog.LevelError),
		IdleTimeout:  time.Minute,
		ReadTimeout:  5 * time.Second,
		WriteTimeout: 5 * time.Second,
	}

	// Start server in a goroutine
	go func() {
		logger.Info("starting server", "addr", srv.Addr)
		err := srv.ListenAndServe()
		if err != nil && err != http.ErrServerClosed {
			logger.Error("server error", "error", err)
			os.Exit(1)
		}
	}()

	// Graceful shutdown
	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, syscall.SIGINT, syscall.SIGTERM)
	<-sigChan

	logger.Info("received signal, shutting down")

	ctx, cancel = context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	err = srv.Shutdown(ctx)
	if err != nil {
		logger.Error("failed to shutdown server", "error", err)
		os.Exit(1)
	}

	logger.Info("server stopped")
	app.wg.Wait()
}

// openDB opens a database connection and returns the connection pool.
func openDB(ctx context.Context, cfg config) (*pgxpool.Pool, error) {
	config, err := pgxpool.ParseConfig(cfg.db.dsn)
	if err != nil {
		return nil, fmt.Errorf("unable to parse connection string: %w", err)
	}

	config.MaxConns = int32(cfg.db.maxOpenConns)
	config.MinConns = int32(cfg.db.maxIdleConns)
	config.MaxConnIdleTime = mustParseDuration(cfg.db.maxIdleTime)

	pool, err := pgxpool.NewWithConfig(ctx, config)
	if err != nil {
		return nil, fmt.Errorf("unable to create connection pool: %w", err)
	}

	// Verify connection
	err = pool.Ping(ctx)
	if err != nil {
		return nil, fmt.Errorf("unable to ping database: %w", err)
	}

	return pool, nil
}

// mustParseDuration parses a duration string or panics if it fails.
func mustParseDuration(s string) time.Duration {
	d, err := time.ParseDuration(s)
	if err != nil {
		panic(fmt.Sprintf("invalid duration: %s", s))
	}
	return d
}

// healthcheckHandler returns the health status of the application.
func (app *application) healthcheckHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	fmt.Fprintf(w, `{"status":"ok","environment":"%s","version":"%s"}`, app.config.env, version)
}
