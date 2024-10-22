TARGET=compat
PROJECT_NAME=game
LUA := $(wildcard *.lua)

LOVEFILE=$(PROJECT_NAME).love

serve: $(LOVEFILE) $(TARGET)
	$(shell ./update-sample.sh; cd $(TARGET); echo "Serving " $(LOVEFILE) ; python3 serve.py)

$(LOVEFILE): $(LUA)
	find $^ -type f | LC_ALL=C sort | env TZ=UTC zip -r -q -9 -X $@ -@

clean: ; rm $(LOVEFILE) index.html
