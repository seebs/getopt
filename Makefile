VERSION=0.5
PACKAGE=LibGetOpt
RIFT=/d/RIFT Game/Interface/AddOns

package:
	rm -rf $(PACKAGE)
	mkdir $(PACKAGE)
	rm -f $(PACKAGE)-$(VERSION).zip
	sed -e "s/VERSION/$(VERSION)/" < RiftAddon.toc > $(PACKAGE)/RiftAddon.toc
	sed -e "s/VERSION/$(VERSION)/" < $(PACKAGE).lua > $(PACKAGE)/$(PACKAGE).lua
	cp *.txt $(PACKAGE)/.

release: package
	zip -r $(PACKAGE)-$(VERSION).zip $(PACKAGE)

install: package
	cp $(PACKAGE)/* "$(RIFT)"/$(PACKAGE)
