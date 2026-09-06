"""
SafeTrade settings.

KANUNI KUU YA UBUNIFU (muhimu kwa uhamaji Render -> AWS):
Hakuna sehemu hapa chini inayotaja "Render" au "AWS" moja kwa moja.
Kila kitu kinachobadilika kati ya mazingira (database, redis, storage,
allowed hosts, secret key) kinasomwa kutoka ENVIRONMENT VARIABLES pekee.

Kuhama kutoka Render kwenda AWS baadaye kunamaanisha: badilisha env vars
zilizowekwa kwenye hosting platform mpya (RDS endpoint, ElastiCache
endpoint, S3 bucket) — HAKUNA line ya code inayohitaji kubadilishwa.
Angalia MIGRATION_TO_AWS.md kwa hatua kamili.
"""

import environ
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent

env = environ.Env(
    DEBUG=(bool, False),
)
environ.Env.read_env(BASE_DIR / ".env")  # .env ni ya local dev pekee; production hutumia env vars za platform

SECRET_KEY = env("DJANGO_SECRET_KEY")
DEBUG = env("DEBUG")
ALLOWED_HOSTS = env.list("ALLOWED_HOSTS", default=["localhost", "127.0.0.1"])
CSRF_TRUSTED_ORIGINS = env.list("CSRF_TRUSTED_ORIGINS", default=[])

INSTALLED_APPS = [
    "django.contrib.admin",
    "django.contrib.auth",
    "django.contrib.contenttypes",
    "django.contrib.sessions",
    "django.contrib.messages",
    "django.contrib.staticfiles",
    "rest_framework",
    "storages",
    "django_celery_beat",
    "core",
]

MIDDLEWARE = [
    "django.middleware.security.SecurityMiddleware",
    "whitenoise.middleware.WhiteNoiseMiddleware",
    "django.contrib.sessions.middleware.SessionMiddleware",
    "django.middleware.common.CommonMiddleware",
    "django.middleware.csrf.CsrfViewMiddleware",
    "django.contrib.auth.middleware.AuthenticationMiddleware",
    "django.contrib.messages.middleware.MessageMiddleware",
    "django.middleware.clickjacking.XFrameOptionsMiddleware",
]

ROOT_URLCONF = "config.urls"

TEMPLATES = [
    {
        "BACKEND": "django.template.backends.django.DjangoTemplates",
        "DIRS": [BASE_DIR / "templates"],
        "APP_DIRS": True,
        "OPTIONS": {
            "context_processors": [
                "django.template.context_processors.debug",
                "django.template.context_processors.request",
                "django.contrib.auth.context_processors.auth",
                "django.contrib.messages.context_processors.messages",
            ],
        },
    },
]

WSGI_APPLICATION = "config.wsgi.application"
AUTH_USER_MODEL = "core.User"

# ---------------------------------------------------------------------------
# DATABASE
# Render na AWS RDS zote mbili zinatoa DATABASE_URL katika muundo sawa wa
# postgres://user:pass@host:port/dbname — kwa hiyo hakuna mabadiliko ya code
# yanayohitajika wakati wa kuhama, isipokuwa kubadilisha env var kwenye
# platform mpya.
# ---------------------------------------------------------------------------
DATABASES = {
    "default": env.db("DATABASE_URL"),
}
DATABASES["default"]["CONN_MAX_AGE"] = 60
DATABASES["default"]["OPTIONS"] = {"sslmode": env("DB_SSL_MODE", default="prefer")}

# ---------------------------------------------------------------------------
# CELERY / REDIS
# ElastiCache (AWS) inatoa endpoint ya redis:// sawa na Render Redis.
# ---------------------------------------------------------------------------
CELERY_BROKER_URL = env("REDIS_URL")
CELERY_RESULT_BACKEND = env("REDIS_URL")
CELERY_ACCEPT_CONTENT = ["json"]
CELERY_TASK_SERIALIZER = "json"
CELERY_BEAT_SCHEDULER = "django_celery_beat.schedulers:DatabaseScheduler"
CELERY_BEAT_SCHEDULE = {
    "resend-pending-digital-receipts": {
        "task": "core.tasks.resend_pending_digital_receipts",
        "schedule": 300.0,  # kila dakika 5 - inatafuta risiti za offline zisizotumwa SMS
    },
    "compute-predictive-alerts": {
        "task": "core.tasks.compute_predictive_alerts",
        "schedule": 3600.0 * 6,  # kila masaa 6
    },
}

# ---------------------------------------------------------------------------
# STORAGE (media files: leseni za biashara, softcopy receipts, picha za bidhaa)
#
# STORAGE_BACKEND=local   -> disk ya ndani (kwa maendeleo tu, si kwa production
#                             ya Render kwa sababu disk ya Render si ya kudumu)
# STORAGE_BACKEND=s3      -> inafanya kazi kwa AWS S3 MOJA KWA MOJA, na pia
#                             kwa huduma yoyote ya S3-compatible (mfano
#                             Cloudflare R2, Backblaze B2) ukiwa Render kabla
#                             ya kuhama AWS. Hii ndiyo ufunguo wa uhamaji
#                             rahisi wa data ya faili: unapohama AWS, badilisha
#                             tu AWS_S3_ENDPOINT_URL kuelekeza S3 halisi na
#                             faili zote tayari ziko kwenye muundo huo huo.
# ---------------------------------------------------------------------------
STORAGE_BACKEND = env("STORAGE_BACKEND", default="local")

if STORAGE_BACKEND == "s3":
    STORAGES = {
        "default": {"BACKEND": "storages.backends.s3.S3Storage"},
        "staticfiles": {"BACKEND": "whitenoise.storage.CompressedManifestStaticFilesStorage"},
    }
    AWS_ACCESS_KEY_ID = env("AWS_ACCESS_KEY_ID")
    AWS_SECRET_ACCESS_KEY = env("AWS_SECRET_ACCESS_KEY")
    AWS_STORAGE_BUCKET_NAME = env("AWS_STORAGE_BUCKET_NAME")
    AWS_S3_REGION_NAME = env("AWS_S3_REGION_NAME", default="af-south-1")
    # Ukiwa Render na unatumia S3-compatible provider isiyo AWS bado, weka
    # endpoint yake hapa. Ukishahama AWS S3 halisi, ondoa/badilisha variable
    # hii pekee.
    AWS_S3_ENDPOINT_URL = env("AWS_S3_ENDPOINT_URL", default=None)
    AWS_DEFAULT_ACL = None
    AWS_S3_FILE_OVERWRITE = False
else:
    STORAGES = {
        "default": {"BACKEND": "django.core.files.storage.FileSystemStorage"},
        "staticfiles": {"BACKEND": "whitenoise.storage.CompressedManifestStaticFilesStorage"},
    }
    MEDIA_URL = "/media/"
    MEDIA_ROOT = BASE_DIR / "media"

STATIC_URL = "/static/"
STATIC_ROOT = BASE_DIR / "staticfiles"
STATICFILES_DIRS = [BASE_DIR / "static"]

REST_FRAMEWORK = {
    "DEFAULT_AUTHENTICATION_CLASSES": (
        "rest_framework_simplejwt.authentication.JWTAuthentication",
    ),
    "DEFAULT_PERMISSION_CLASSES": (
        "rest_framework.permissions.IsAuthenticated",
    ),
}

LANGUAGE_CODE = "en-us"
TIME_ZONE = "Africa/Dar_es_Salaam"
USE_I18N = True
USE_TZ = True

DEFAULT_AUTO_FIELD = "django.db.models.BigAutoField"
