import os
from pathlib import Path

BASE_DIR = Path(__file__).parent.parent

DB_CONFIG = {
    'host': os.getenv('DB_HOST', 'localhost'),
    'port': int(os.getenv('DB_PORT', '5432')),
    'database': os.getenv('DB_NAME', 'boutique_vertice_dw'),
    'user': os.getenv('DB_USER', 'postgres'),
    'password': os.getenv('DB_PASSWORD', 'postgres')
}

EXCEL_HISTORICO = BASE_DIR / 'data' / 'Carga_Historica_2025_2026.xlsx'
EXCEL_DIARIO = BASE_DIR / 'data' / 'Carga_Diaria.xlsx'

LOG_FILE = BASE_DIR / 'logs' / 'etl_log.txt'

BATCH_SIZE = 1000