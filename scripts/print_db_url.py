import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from utils.keyvault import get_db_dsn

if __name__ == "__main__":
    environment = sys.argv[1] if len(sys.argv) > 1 else None
    print(get_db_dsn(environment))
