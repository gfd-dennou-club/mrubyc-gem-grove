SRC_DIR := src
DST_DIR := mrblib

# src -> mrblib へのコピー
select:
	@mkdir -p $(DST_DIR)
	@ls $(SRC_DIR)/*.rb | fzf -m \
		--header "Select files to COPY to $(DST_DIR) (Tab to select)" \
		--preview 'cat {}' \
		| xargs -I {} cp -v {} $(DST_DIR)/

# mrblib からの削除
remove:
	@ls $(DST_DIR)/*.rb 2>/dev/null | fzf -m \
		--header "Select files to DELETE from $(DST_DIR) (Tab to select)" \
		--preview 'cat {}' \
		| xargs -r rm -v
