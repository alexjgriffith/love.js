TARGET=compat
PROJECT_NAME=game

LOVEFILE=$(PROJECT_NAME).love

update:
	$(shell cd game && find -type f | LC_ALL=C sort | env TZ=UTC zip -r -q -9 -X ../${LOVEFILE} -@)
	./update-sample.sh

serve: $(LOVEFILE) $(TARGET)
	$(shell ./update-sample.sh; cd $(TARGET); echo "Serving " $(LOVEFILE) ; python3 ../serve.py)

# $(LOVEFILE):
# 	$(shell cd game && find -type f | LC_ALL=C sort | env TZ=UTC zip -r -q -9 -X ../$@ -@)

clean: ; rm $(LOVEFILE) index.html
