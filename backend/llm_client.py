"""LLM client supporting Ollama and OpenAI."""
from typing import Optional, List, Dict, Any
from langchain_openai import ChatOpenAI
from langchain_community.chat_models import ChatOllama
from langchain.schema import BaseMessage, HumanMessage, SystemMessage
from config import settings


class LLMClient:
    """Unified LLM client supporting multiple providers."""
    
    def __init__(self):
        self.provider = settings.llm_provider
        self.llm = self._create_llm()
    
    def _create_llm(self):
        """Create LLM instance based on provider."""
        if self.provider == "openai":
            if not settings.openai_api_key:
                raise ValueError("OpenAI API key not set")
            return ChatOpenAI(
                model=settings.openai_model,
                temperature=0.7,
                openai_api_key=settings.openai_api_key
            )
        else:  # ollama
            return ChatOllama(
                model=settings.ollama_model,
                base_url=settings.ollama_base_url,
                temperature=0.7
            )
    
    def invoke(
        self,
        messages: List[BaseMessage],
        **kwargs
    ) -> str:
        """Invoke LLM with messages."""
        return self.llm.invoke(messages, **kwargs).content
    
    def stream(self, messages: List[BaseMessage]):
        """Stream LLM responses."""
        return self.llm.stream(messages)


# Singleton instance
llm_client = LLMClient()






