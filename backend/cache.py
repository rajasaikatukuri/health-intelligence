"""Query result caching."""
import json
import pickle
from typing import Optional, Any, Dict
from config import settings

# In-memory cache (for dev)
_cache: Dict[str, tuple] = {}


class Cache:
    """Simple in-memory cache (can be replaced with Redis)."""
    
    def __init__(self):
        self._cache: Dict[str, tuple] = {}
        self._redis = None
        
        if settings.redis_enabled:
            try:
                import redis
                self._redis = redis.Redis(
                    host=settings.redis_host,
                    port=settings.redis_port,
                    db=settings.redis_db,
                    decode_responses=False
                )
                self._redis.ping()
            except Exception:
                # Redis not available, use in-memory
                pass
    
    def get(self, key: str) -> Optional[Any]:
        """Get cached value."""
        if self._redis:
            try:
                data = self._redis.get(key)
                if data:
                    return pickle.loads(data)
            except Exception:
                pass
        
        # Fallback to in-memory
        if key in self._cache:
            value, expiry = self._cache[key]
            import time
            if time.time() < expiry:
                return value
            else:
                del self._cache[key]
        
        return None
    
    def set(self, key: str, value: Any, ttl: int = None) -> None:
        """Set cached value."""
        ttl = ttl or settings.query_cache_ttl
        import time
        expiry = time.time() + ttl
        
        if self._redis:
            try:
                self._redis.setex(
                    key,
                    ttl,
                    pickle.dumps(value)
                )
                return
            except Exception:
                pass
        
        # Fallback to in-memory
        self._cache[key] = (value, expiry)
    
    def clear(self) -> None:
        """Clear all cache."""
        if self._redis:
            try:
                self._redis.flushdb()
            except Exception:
                pass
        self._cache.clear()


cache = Cache()

