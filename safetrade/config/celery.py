import os
from celery import Celery

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "config.settings")

# Jina "app" hapa halibadiliki kati ya Render na AWS - Celery inasoma
# broker/result backend kutoka CELERY_BROKER_URL / CELERY_RESULT_BACKEND
# ambazo tayari zinatoka kwenye settings.py (nazo kutoka env vars).
app = Celery("safetrade")
app.config_from_object("django.conf:settings", namespace="CELERY")
app.autodiscover_tasks()
