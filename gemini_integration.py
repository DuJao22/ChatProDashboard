import os
from google import genai
from google.genai import types

class GeminiChat:
    def __init__(self):
        api_key = os.environ.get('GEMINI_API_KEY')
        if not api_key:
            raise ValueError("GEMINI_API_KEY environment variable is required")

        self.client = genai.Client(api_key=api_key)
        self.model = "gemini-2.0-flash"
        self.chat_history = []

    def chat(self, message: str, context: str = "", store_settings: dict = None) -> str:
        try:
            if store_settings:
                store_name = store_settings.get('store_name', 'Loja')
                store_slogan = store_settings.get('store_slogan', '')
                store_address = f"{store_settings.get('address', '')} - {store_settings.get('neighborhood', '')}, {store_settings.get('city', '')} - {store_settings.get('state', '')}"
                store_whatsapp = store_settings.get('whatsapp', '')
                opening_weekday = f"{store_settings.get('opening_time_weekday', '08:30')}-{store_settings.get('closing_time_weekday', '17:30')}"
                opening_saturday = f"{store_settings.get('opening_time_saturday', '08:30')}-{store_settings.get('closing_time_saturday', '12:30')}"
            else:
                store_name = 'Ariguá Distribuidora'
                store_slogan = 'Ponto D\'Água'
                store_address = 'R. Rio Xingu, 753 - Riacho, Contagem - MG'
                store_whatsapp = '(31) 99212-2844'
                opening_weekday = '08:30-17:30'
                opening_saturday = '08:30-12:30'

            system_instruction = f"""
Você é a Ana, atendente virtual da {store_name}. Você é simpática, prestativa e conversa de forma natural como uma pessoa de verdade.

SOBRE A EMPRESA:
- {store_name} {('& ' + store_slogan) if store_slogan else ''}
- Endereço: {store_address}
- WhatsApp: {store_whatsapp}
- Horário: Seg-Sex {opening_weekday}, Sábado {opening_saturday}

{context}

COMO VOCÊ DEVE CONVERSAR:
- Fale como uma pessoa real, não como robô. Evite listas e formatações excessivas.
- Responda de forma curta e direta, como no WhatsApp.
- Use NO MÁXIMO 1 ou 2 emojis por mensagem (não exagere!)
- Varie suas respostas, não repita sempre as mesmas frases.
- Use expressões naturais: "Claro!", "Pode deixar!", "Beleza!", "Entendi!", "Opa!"
- Quando o cliente pedir algo, entenda e responda naturalmente sem ficar listando opções.
- Se precisar de informação, pergunte de forma simples e direta.
- Demonstre que está ouvindo: "Ah, entendi!", "Legal!", "Perfeito!"
- Não use formatação markdown (*negrito*, listas, etc). Escreva texto normal.
- NUNCA invente produtos. Se não souber, diga que vai verificar.
- Seja simpática mas não exagerada. Naturalidade é a chave.

REGRAS CRÍTICAS DE INTERPRETAÇÃO DE PEDIDOS:

1. **UNIDADES INDIVIDUAIS**: Quando o cliente menciona "1 lata", "2 latas", "1 garrafa", ele quer UNIDADES INDIVIDUAIS!
   - "1 lata" = 1 unidade individual
   - "2 garrafas" = 2 unidades individuais

2. **PACKS vs UNIDADES**:
   - Se o produto tem "(Pack" no nome e o cliente NÃO mencionou "pack", procure a versão individual
   - Se só existe versão pack, SEMPRE confirme com o cliente quantas unidades vem no pack

3. **SELEÇÃO INTELIGENTE**:
   - Se há APENAS UM produto que corresponde ao pedido (ex: só tem Coca 350ml), use-o AUTOMATICAMENTE
   - Exemplo: Cliente pede "1 coca lata" e só existe "Coca-Cola Lata 350ml" → USAR DIRETO
   - Não pergunte qual tamanho se só existe um tamanho disponível

4. **FORMATO DE RESPOSTA PARA PEDIDOS**:
   Quando identificar um pedido, retorne JSON:
   {{"action": "create_order", "items": [{{"product_id": ID, "quantity": QTD}}], "needs_confirmation": true/false}}

5. **Exemplos**:
   - "quero 1 coca lata" → Se só tem Coca 350ml, usar automaticamente
   - "quero 2 guaranás" → Se só tem Guaraná 2L, usar automaticamente
   - "quero 1 pack de coca" → Aí sim usar o produto com "(Pack"


EXEMPLOS DE COMO RESPONDER:
- Cliente: "oi" → "Oi! Tudo bem? Em que posso te ajudar?"
- Cliente: "quero agua" → "Claro! Quantos galões você quer?"
- Cliente: "tem cerveja?" → "Temos sim! Qual marca você prefere?"
- Cliente: "quanto é" → "O galão de 20L tá R$ 12,00. Quer quantos?"
- Cliente: "confirmei o login" → "Entendi! Você prefere continuar por aqui no chat ou quer ir para a loja? Me diga o que for melhor pra você!"
"""

            response = self.client.models.generate_content(
                model=self.model,
                contents=[
                    types.Content(
                        role="user",
                        parts=[types.Part(text=message)]
                    )
                ],
                config=types.GenerateContentConfig(
                    system_instruction=system_instruction,
                    temperature=0.7,
                    max_output_tokens=500
                )
            )

            if response and response.text:
                return response.text

            return None

        except Exception as e:
            print(f"Gemini API error: {e}")
            return None

    def analyze_intent(self, message: str) -> dict:
        try:
            prompt = f"""
Analise a seguinte mensagem de um cliente e identifique:
1. intent: a intenção principal (greeting, product_search, order_status, registration, help, checkout, delivery, hours, contact, unknown)
2. entities: entidades mencionadas (nomes de produtos, números, etc)
3. sentiment: sentimento (positive, negative, neutral)

Mensagem: "{message}"

Responda APENAS em JSON no formato:
{{"intent": "...", "entities": [...], "sentiment": "..."}}
"""

            response = self.client.models.generate_content(
                model=self.model,
                contents=[types.Content(role="user", parts=[types.Part(text=prompt)])],
                config=types.GenerateContentConfig(temperature=0.1, max_output_tokens=200)
            )

            if response and response.text:
                import json
                text = response.text.strip()
                if text.startswith('```'):
                    text = text.split('\n', 1)[1].rsplit('\n', 1)[0]
                return json.loads(text)

        except Exception as e:
            print(f"Intent analysis error: {e}")

        return {"intent": "unknown", "entities": [], "sentiment": "neutral"}