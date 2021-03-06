# VCReport

VCReport is a tool for generating reports on files used in genomic variant call such as VCF and CRAM.

The tool is able to monitor a directory where the variant calling of multiple samples is in progress. It generates:

* progress report
* metrics report on each sample
* dashboard (metrics across samples)

## Installation

As a prerequisite, the following should be installed.
* Ruby (>= 2.7.0)
* Singularity
* [cwltool](https://github.com/common-workflow-language/cwltool)

VCReport is provided as a Ruby gem. Since the gem is not registered in RubyGems currently, it should be built and installed locally.

```
$ git clone <THIS REPOSITORY>
$ cd vcreport
$ git submodule update --init
$ bundle install
$ rake build
$ gem install --local pkg/*.gem
```

## Usage

### Directory structure and settings

In VCReport, variant call project is managed per directory. The project directory is supposed to have the following structure.

```
<project dir>/
  +-- results/
  |  +-- <sample0>/
  |  +-- <sample1>/
  |  +-- <sample2>/
  |      ...
  +--- reports/
  +--- vcreport/
  +--- vcreport.yaml
```

Each sample data should be placed in `results` directory by the user. VCReport creates `reports` directory, where report HTML files are generated. It also creates `vcreport` directory used for management and logging. The user has to describe `vcreport.yaml` needed to run VCReport properly.

The name of a sample directory should be identical to the sample name. If the name of the sample is `AAA`, the name of the directory is also `AAA`. The CRAM file used for variant call is supposed to be `AAA.cram`. There may be multiple VCF files calculated on given genomic intervals. If the interval name is `BBB`, the name of VCF file is supposed to be `AAA.BBB.g.vcf.gz`. In order to tell VCReport that CRAM and VCFs are already created, `finish` file should be put in a sample directory.

The structure of `vcreport.yaml` is like the following.

```
reference:
  desc: GRCh38
  path: /path/to/reference.fasta
vcf:
  regions:
    autosome:
      desc: autosomal region
    chrX:
      desc: chrX
    chrY:
      desc: chrY
metrics:
  picard_CollectWgsMetrics:
    minimum_base_quality: 10
    minimum_mapping_quality: 10
    interval_list:
      autosome:
        desc: autosome
        path: /path/to/autosome.interval_list
      chrX:
        desc: chrX
        path: /path/to/chrX.interval_list
      chrY:
        desc: chrY
        path: /path/to/chrY.interval_list
```

### Command line

For directory monitoring `vcreport monitor` command is used.

```
$ vcreport monitor start <project dir>
```

When `vcreport monitor start` is run, a monitoring daemon is launched. The daemon periodically (by default, per hour) generates reports on samples. If files on new samples are added to the project directory, metrics calculations are automatically performed.

To check the staus of the daemon, use `vcreport monitor status` command.

```
$ vcreport monitor status <project dir>
```

The daemon is terminated by the following command.

```
$ vcreport monitor stop <project dir>
```

Instead of periodical monitoring, one-time report generation and metrics calculation are also possible. For report file rendering, run

```
$ vcreport render <project dir>
```

and for metrics calculation, run the following.

```
$ vcreport metrics <project dir>
```

VCReport also provides a simple web server.

```
$ vcreport http <project dir> -p <port number>
```

## License

The gem is available as open source under the terms of the [Apache-2.0](https://www.apache.org/licenses/LICENSE-2.0).

## Code of Conduct

Everyone interacting in the VCReport project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/tafujino/vcreport/blob/master/CODE_OF_CONDUCT.md).
