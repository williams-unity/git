#!/bin/sh

test_description='ls-tree with sparse filter patterns'

TEST_PASSES_SANITIZE_LEAK=true
. ./test-lib.sh

test_output () {
    sed -e "s/ $OID_REGEX	/ X	/" <current >check
    test_cmp expected check
}

test_expect_success 'setup' '
	mkdir dir &&
	test_commit dir/sub-file &&
	test_commit dir/sub-file2 &&
	mkdir dir2 &&
	test_commit dir2/sub-file1 &&
	test_commit dir2/sub-file2 &&
	test_commit top-file &&
	git clone . submodule &&
	git submodule add ./submodule &&
	git commit -m"add submodule"
'

test_expect_success 'toplevel filter only shows toplevel file' '
	filter_oid=$(git hash-object -w --stdin <<-\EOF
	/*
	!/*/
	EOF
	) &&
	cat >expect <<-EOF &&
	.gitmodules
	submodule
	top-file.t
	EOF
	git ls-tree --name-only --filter-sparse-oid=${filter_oid} -r HEAD >actual &&
	test_cmp expect actual
'

test_expect_success 'non cone single file filter' '
	filter_oid=$(git hash-object -w --stdin <<-\EOF
	dir/sub-file.t
	EOF
	) &&
	cat >expect <<-EOF &&
	dir/sub-file.t
	EOF
	git ls-tree --name-only --filter-sparse-oid=${filter_oid} -r HEAD >actual &&
	test_cmp expect actual
'

test_expect_success 'cone filter matching one dir' '
	filter_oid=$(git hash-object -w --stdin <<-\EOF
	/*
	!/*/
	/dir/
	EOF
	) &&
	cat >expect <<-EOF &&
	.gitmodules
	dir/sub-file.t
	dir/sub-file2.t
	submodule
	top-file.t
	EOF
	git ls-tree --name-only --filter-sparse-oid=${filter_oid} -r HEAD >actual &&
	test_cmp expect actual
'

test_done
