# test/git-import-all_test.rb

require 'date'
require 'fileutils'
require 'minitest/autorun'
require 'open3'
require 'tmpdir'
require 'yaml'

BIN = File.expand_path('../bin/git-import-all', __dir__)
LIB = File.expand_path('../lib', __dir__)

# A throwaway repository, its commits unsigned and its committer stated, so
# that an import into it depends on nothing of the machine's own git config.
def make_repo(path)
  FileUtils.mkdir_p(path)
  git(path, 'init', '-q')
  git(path, 'config', 'commit.gpgsign', 'false')
  git(path, 'config', 'user.name', 'Test')
  git(path, 'config', 'user.email', 'test@example.com')
  path
end

def git(repo, *args)
  output, status = Open3.capture2e('git', '-C', repo, *args)
  raise "git #{args.join(' ')} failed: #{output}" unless status.success?
  output
end

def write_revision(root, number, files)
  files.each do |name, content|
    path = File.join(root, number.to_s, name)
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, content)
  end
end

def write_revisions_yml(root, revisions)
  File.write(File.join(root, 'revisions.yml'), YAML.dump('revisions' => revisions))
end

def import(repo, root)
  Open3.capture3('ruby', '-I', LIB, BIN, repo, root)
end

def commit_count(repo)
  output, status = Open3.capture2e('git', '-C', repo, 'rev-list', '--count', '--all')
  status.success? ? output.to_i : 0
end

def log(repo, format)
  git(repo, 'log', '--reverse', "--format=#{format}").lines.map(&:chomp)
end

def local_midnight(day)
  Date.parse(day).to_time.strftime('%Y-%m-%d %H:%M:%S %z')
end

describe 'git-import-all' do
  before do
    @dir = Dir.mktmpdir
    @repo = make_repo(File.join(@dir, 'the repo'))
    @root = File.join(@dir, 'revisions root')
    FileUtils.mkdir_p(@root)
  end

  after do
    FileUtils.rm_rf(@dir)
  end

  describe 'with a revisions.yml' do
    before do
      write_revision(@root, 0, {'lib/Voices.rb' => "# 0.0.0\n", 'CHANGELOG' => "## 20990101\n\n9.9.9: Not this.\n"})
      write_revision(@root, 1, {'lib/Voices.rb' => "# 0.0.0\n", 'lib/OSX/Dmg.rb' => "# 0.0.0\n"})
      write_revision(@root, 2, {'lib/OSX/Dmg.rb' => "# 0.1.0\n"})
      write_revisions_yml(@root, [
        {'revision' => 0, 'time' => '2010-05-28 20:17:34 +1000', 'message' => 'Voices.rb 0.0.0: + Voices.', 'series' => 'Voices', 'series_revision' => 0},
        {'revision' => 1, 'time' => '2013-06-22', 'message' => 'OSX/Dmg.rb 0.0.0: + OSX::Dmg.', 'files' => ['lib/OSX/Dmg.rb']},
        {'revision' => 2, 'time' => '2013-06-21 09:00:00 -0500', 'message' => "OSX/Dmg.rb 0.1.0: Shellwords.\n\n1. + require 'shellwords'\n\n\n2. ~ mount, with  two spaces.  \n# not a comment"},
      ])
      @started = Time.now.to_i
      @output, @error, @status = import(@repo, @root)
    end

    it 'makes one commit per revision' do
      _(@status.success?).must_equal true, @error
      _(commit_count(@repo)).must_equal 3
    end

    it 'takes the subjects from the file, not from any CHANGELOG' do
      _(log(@repo, '%s')).must_equal ['Voices.rb 0.0.0: + Voices.', 'OSX/Dmg.rb 0.0.0: + OSX::Dmg.', 'OSX/Dmg.rb 0.1.0: Shellwords.']
    end

    it 'commits a message of several lines exactly as written' do
      message = git(@repo, 'log', '-1', '--format=%B')
      _(message).must_equal "OSX/Dmg.rb 0.1.0: Shellwords.\n\n1. + require 'shellwords'\n\n\n2. ~ mount, with  two spaces.  \n# not a comment\n\n"
    end

    it 'takes the author dates from the times, keeping their zones, and allows them to run backwards' do
      _(log(@repo, '%ai')).must_equal ['2010-05-28 20:17:34 +1000', local_midnight('2013-06-22'), '2013-06-21 09:00:00 -0500']
    end

    it 'leaves the committer dates fresh' do
      log(@repo, '%ct').each{|committed| _(committed.to_i).must_be :>=, @started}
    end

    it 'leaves the tree as the last revision' do
      _(git(@repo, 'ls-files').lines.map(&:chomp)).must_equal ['lib/OSX/Dmg.rb']
    end
  end

  describe 'refusing a revisions.yml' do
    before do
      write_revision(@root, 0, {'a.txt' => "a\n"})
      write_revision(@root, 1, {'a.txt' => "b\n"})
    end

    def entry(revision, overrides = {})
      {'revision' => revision, 'time' => '2020-01-01', 'message' => "#{revision}.0.0: Revision #{revision}."}.merge(overrides)
    end

    def refuses(pattern)
      _output, error, status = import(@repo, @root)
      _(status.success?).must_equal false
      _(error).must_match pattern
      _(commit_count(@repo)).must_equal 0
      _(Dir.children(@repo)).must_equal ['.git']
    end

    it 'refuses a file without a top-level revisions list' do
      File.write(File.join(@root, 'revisions.yml'), YAML.dump([entry(0), entry(1)]))
      refuses(/revisions\.yml has no top-level revisions list/)
    end

    it 'refuses a file which does not parse' do
      File.write(File.join(@root, 'revisions.yml'), "revisions: [\n")
      refuses(/revisions\.yml does not parse/)
    end

    it 'refuses fewer entries than directories' do
      write_revisions_yml(@root, [entry(0)])
      refuses(/no entry for directory 1: 1 entries for 2 revisions/)
    end

    it 'refuses more entries than directories' do
      write_revisions_yml(@root, [entry(0), entry(1), entry(2)])
      refuses(/revisions\[2\] has no directory: 3 entries for 2 revisions/)
    end

    it 'refuses entries out of order' do
      write_revisions_yml(@root, [entry(1), entry(0)])
      refuses(/revisions\[0\] states revision 1 where the directory at its place is 0/)
    end

    it 'refuses a revision which is not a number' do
      write_revisions_yml(@root, [entry(0), entry('1')])
      refuses(/revisions\[1\] states revision "1"/)
    end

    it 'refuses an entry which is not a mapping' do
      write_revisions_yml(@root, [entry(0), 'revision 1'])
      refuses(/revisions\[1\] is not a mapping/)
    end

    it 'refuses a time which does not parse' do
      ['2020-02-30', '2020-01-01 25:00:00 +1000', '2020-01-01 10:00:00', 'yesterday', nil].each do |time|
        write_revisions_yml(@root, [entry(0), entry(1, 'time' => time)])
        refuses(/revisions\[1\] has a time which does not parse: #{Regexp.escape(time.inspect)}/)
      end
    end

    it 'refuses a time which is not a quoted string' do
      File.write(File.join(@root, 'revisions.yml'), YAML.dump('revisions' => [entry(0), entry(1)]).sub("'2020-01-01'", '2020-01-01'))
      refuses(/revisions\[0\] has a time which does not parse/)
    end

    it 'refuses a missing, empty or other than textual message' do
      [nil, '', "  \n", 7].each do |message|
        write_revisions_yml(@root, [entry(0), entry(1, 'message' => message)])
        refuses(/revisions\[1\] has no message/)
      end
    end
  end

  describe 'without a revisions.yml' do
    it 'takes the messages and dates from the CHANGELOG, as before' do
      changelog = "## 20260102\n\n0.1.0: Second.\n\n1. ~ a.txt\n\n\n## 20260101\n\n0.0.0: First.\n"
      write_revision(@root, 0, {'a.txt' => "a\n"})
      write_revision(@root, 1, {'a.txt' => "b\n", 'CHANGELOG' => changelog})
      _output, error, status = import(@repo, @root)
      _(status.success?).must_equal true, error
      _(log(@repo, '%B')).must_equal ['0.0.0: First.', '', '0.1.0: Second.', '']
      _(log(@repo, '%ai')).must_equal [local_midnight('2026-01-01'), local_midnight('2026-01-02')]
    end

    it 'still refuses a CHANGELOG whose entries and revisions disagree' do
      write_revision(@root, 0, {'a.txt' => "a\n"})
      write_revision(@root, 1, {'a.txt' => "b\n", 'CHANGELOG' => "## 20260101\n\n0.0.0: First.\n"})
      _output, error, status = import(@repo, @root)
      _(status.success?).must_equal false
      _(error).must_match(/1 CHANGELOG entries for 2 revisions/)
      _(commit_count(@repo)).must_equal 0
    end
  end

  describe 'with a space in a name' do
    it 'imports a top-level name with a space, into a repository with one, and removes it again' do
      write_revision(@root, 0, {'a b.txt' => "a\n", 'c d/e f.txt' => "e\n"})
      write_revision(@root, 1, {'g.txt' => "g\n"})
      write_revisions_yml(@root, [
        {'revision' => 0, 'time' => '2020-01-01', 'message' => '0.0.0: Spaces.'},
        {'revision' => 1, 'time' => '2020-01-02', 'message' => '0.1.0: No spaces.'},
      ])
      _output, error, status = import(@repo, @root)
      _(status.success?).must_equal true, error
      _(git(@repo, 'ls-tree', '-r', '--name-only', 'HEAD~1').lines.map(&:chomp)).must_equal ['a b.txt', 'c d/e f.txt']
      _(git(@repo, 'ls-tree', '-r', '--name-only', 'HEAD').lines.map(&:chomp)).must_equal ['g.txt']
      _(Dir.children(@repo).sort).must_equal ['.git', 'g.txt']
    end
  end
end
